require("hs.ipc")
function HS_Ping() return "pong" end
local APP_NAME = "Cursor"
local CHAT_HOTKEY_MODS = {"cmd", "shift"}
local CHAT_HOTKEY_KEY = "I"

local function sleep(sec) hs.timer.usleep(sec * 1e6) end

local function activate_app(maxTries)
  maxTries = maxTries or 3
  for i = 1, maxTries do
    local app = hs.application.find(APP_NAME)
    if not app then
      hs.application.launchOrFocus(APP_NAME)
      sleep(0.35)
    else
      app:activate()
      sleep(0.15)
    end

    local front = hs.application.frontmostApplication()
    if front and front:name() == APP_NAME then
      return true
    end
    sleep(0.25)
  end
  print("[HS] activate_app FAILED: cannot bring Cursor to front")
  return false
end

function SendToCursor(text, opts)
  opts = opts or {}
  local dActivate      = tonumber(opts.delayActivate    or 0.15)
  local dOpen          = tonumber(opts.delayOpen        or 0.35)
  local dClipboard     = tonumber(opts.delayClipboard   or 0.10)
  local dPaste         = tonumber(opts.delayPaste       or 0.08)
  local dBeforeSend    = tonumber(opts.delayBeforeSend  or 0.05)
  local doTypeFallback = (opts.typeFallback ~= false)

  if not text or text == "" then return false, "no_text" end
  if not activate_app(3) then return false, "launch_failed" end
  sleep(dActivate)

  hs.eventtap.keyStroke(CHAT_HOTKEY_MODS, CHAT_HOTKEY_KEY, 0)
  sleep(dOpen)

  do
    local app = hs.application.frontmostApplication()
    local win = app and (app:focusedWindow() or app:mainWindow())
    if win then
      local f = win:frame()
      local clickPos = { x = f.x + f.w - 80, y = f.y + 90 }
      hs.eventtap.leftClick(clickPos)
      sleep(0.08)
    end
  end

  hs.pasteboard.setContents(text)
  sleep(dClipboard)

  hs.eventtap.keyStroke({"cmd"}, "v", 0)
  sleep(dPaste)

  hs.eventtap.keyStroke({"cmd"}, "a", 0)
  sleep(0.02)
  hs.eventtap.keyStroke({"cmd"}, "v", 0)
  sleep(dPaste)

  if doTypeFallback then
    hs.eventtap.keyStrokes(text)
    sleep(0.05)
  end

  local front = hs.application.frontmostApplication()
  if not front or front:name() ~= APP_NAME then
    activate_app(2)
    sleep(0.12)
  end

  sleep(dBeforeSend)
  hs.eventtap.keyStroke({}, "return", 0)

  return true
end

if not HS_Ping then
  function HS_Ping() return "pong" end
end

local function sleep(sec) if sec and sec > 0 then hs.timer.usleep(sec * 1e6) end end

local function log(fmt, ...)
  print(string.format("[HS] " .. fmt, ...))
end

local function writeFile(path, str)
  local f, err = io.open(path, "w")
  if not f then return nil, err end
  f:write(str)
  f:close()
  return true
end

function RunCase(case_id, text, opts)
  opts = opts or {}
  local retries   = tonumber(opts.retries or 3)
  local gapAfter  = tonumber(opts.gapAfter or 0.3)

  if case_id and case_id ~= "" then
    text = string.format("%s", text or "")
  end

  for attempt = 1, retries do
    local ok, err = SendToCursor(text, {
      delayActivate   = 0.15,
      delayOpen       = 0.4,
      delayClipboard  = 0.06,
      delayPaste      = 0.09,
      delayBeforeSend = 0.06,
      typeFallback = false,
    })
    if ok then
      sleep(gapAfter)
      return true
    end
    log("RunCase FAILED (%s) attempt=%d/%d", tostring(err), attempt, retries)
    sleep(0.35)
  end
  return false
end

function RunSuiteInline(cases, opts)
  opts = opts or {}
  local delayOpen       = tonumber(opts.delayOpen or 0.25)
  local delayAfterPaste = tonumber(opts.delayAfterPaste or 0.1)
  local gapAfter        = tonumber(opts.gapAfter or 0.4)
  local retries         = tonumber(opts.retries or 3)
  local reportPath      = opts.report
  local cfg             = opts.config

  local results = { total = #cases, ok = 0, fail = 0, items = {} }
  log("RunSuiteInline start; total=%d", results.total)

  for idx, item in ipairs(cases) do
    local cid  = item.case or string.format("CASE_%04d", idx)
    local text = item.text or ""
    log("[%d/%d] Sending %s", idx, results.total, cid)

    local ok = RunCase(cid, text, {
      retries         = retries,
      delayOpen       = delayOpen,
      delayAfterPaste = delayAfterPaste,
      gapAfter        = gapAfter,
      config          = cfg,
    })

    if ok then
      results.ok = results.ok + 1
      table.insert(results.items, {case=cid, ok=true})
    else
      results.fail = results.fail + 1
      table.insert(results.items, {case=cid, ok=false})
    end

    sleep(30)
  end

  log("RunSuiteInline done. OK=%d FAIL=%d", results.ok, results.fail)

  if reportPath then
    local js = hs.json.encode(results, true)
    local ok, err = writeFile(reportPath, js)
    if ok then hs.alert.show("Report saved: "..reportPath)
    else hs.alert.show("Report save failed: "..tostring(err)) end
  end

  return results
end

function RunSuiteFromTSV(path, opts)
  local cases = {}
  local f, err = io.open(path, "r")
  if not f then
    hs.alert.show("Open TSV failed: "..tostring(err))
    return nil, err
  end

  for line in f:lines() do
    if line and line:gsub("%s+", "") ~= "" and line:sub(1,1) ~= "#" then
      local case_id, text = line:match("([^\t]+)\t(.+)")
      if case_id and text then
        table.insert(cases, {case=case_id, text=text})
      end
    end
  end
  f:close()

  if #cases == 0 then
    hs.alert.show("No valid rows in TSV")
    return { total=0, ok=0, fail=0, items={} }
  end
  return RunSuiteInline(cases, opts)
end

function RunSuiteFilePicker(opts)
  local btn, files = hs.dialog.chooseFileOrFolder("Select a TSV file", os.getenv("HOME"), false, false, {"tsv"})
  if btn ~= "OK" or not files or #files == 0 then
    hs.alert.show("Canceled")
    return
  end
  local path = files[1]
  RunSuiteFromTSV(path, opts)
end

local function expanduser(p)
  if not p then return p end
  local home = os.getenv("HOME") or "~"
  p = p:gsub("^~", home)
  local abs = hs.fs.pathToAbsolute(p)
  return abs or p
end

local function file_exists(p) return p and hs.fs.attributes(p) ~= nil end

local function read_file(p)
  local f, err = io.open(p, "r"); if not f then return nil, err end
  local s = f:read("*a"); f:close(); return s
end

local function write_file_overwrite(dst, data)
  local dst_exp = expanduser(dst)
  local dir = dst_exp:match("^(.*)/[^/]+$")
  if dir then hs.fs.mkdir(dir) end
  local tmp = dst_exp .. ".tmp_" .. tostring(hs.timer.secondsSinceEpoch())
  local f, err = io.open(tmp, "w"); if not f then return nil, "open_tmp_failed:"..tostring(err) end
  f:write(data); f:close()
  os.remove(dst_exp)
  local ok, rerr = os.rename(tmp, dst_exp)
  if not ok then return nil, "rename_failed:"..tostring(rerr) end
  return dst_exp
end

local function is_cursor_running()
  return hs.application.find(APP_NAME) ~= nil
end

local function quit_cursor_hard(timeout)
  timeout = timeout or 4.0
  print("[HS] quitting Cursor gracefully (Cmd+Q)...")

  activate_app(2)
  sleep(0.3)

  hs.eventtap.keyStroke({"cmd"}, "q", 0)
  sleep(0.5)

  local deadline = hs.timer.secondsSinceEpoch() + timeout
  while hs.timer.secondsSinceEpoch() < deadline do
    if not is_cursor_running() then
      print("[HS] Cursor quit successfully via Cmd+Q")
      return true
    end
    hs.timer.usleep(200000)
  end

  print("[HS] Cmd+Q ineffective, trying AppleScript quit ...")
  hs.osascript.applescript('tell application "'..APP_NAME..'" to quit')
  sleep(1.0)
  if not is_cursor_running() then
    print("[HS] Cursor quit successfully via AppleScript")
    return true
  end

  print("[HS] warn: forcing kill on Cursor ...")
  local app = hs.application.find(APP_NAME)
  if app then app:kill() end
  hs.execute('pkill -x '..APP_NAME, true)
  sleep(0.5)

  local alive = is_cursor_running()
  if alive then
    print("[HS] ERROR: Cursor still running after kill")
  else
    print("[HS] Cursor killed")
  end
  return not alive
end

local function launch_cursor_and_wait(timeout)
  timeout = timeout or 5.0
  hs.application.launchOrFocus(APP_NAME)
  local deadline = hs.timer.secondsSinceEpoch() + timeout

  while hs.timer.secondsSinceEpoch() < deadline do
    local app = hs.application.find(APP_NAME)
    if app and #app:allWindows() > 0 then
      app:activate()
      sleep(0.15)
      return true
    end
    sleep(0.2)
  end

  hs.osascript.applescript('tell application "'..APP_NAME..'" to activate')
  sleep(0.6)
  local app2 = hs.application.find(APP_NAME)
  if app2 then
    app2:activate()
    sleep(0.2)
    return true
  end

  print("[HS] launch_cursor_and_wait: timeout / cannot show window")
  return false
end

local function resolve_case_json(dir, caseId)
  local d = expanduser(dir)
  local cand1 = d .. "/" .. caseId .. ".json"
  if file_exists(cand1) then return cand1 end
  local num = tostring(caseId):match("(%d+)")
  if num then
    local cand2 = d .. "/" .. tostring(tonumber(num)) .. ".json"
    if file_exists(cand2) then return cand2 end
    local cand3 = d .. "/" .. num .. ".json"
    if file_exists(cand3) then return cand3 end
  end
  return nil
end

function switch_config_for_case(caseId, cfg)
  if not cfg or not cfg.dir then return true end

  local src = resolve_case_json(cfg.dir, caseId)
  if not src then
    print(string.format("[HS] config not found: case=%s dir=%s", tostring(caseId), tostring(cfg.dir)))
    return nil, "config_not_found"
  end

  local dst = expanduser(cfg.dst or "~/.cursor/mcp.json")
  print(string.format("[HS] switch_config: case=%s src=%s -> dst=%s", tostring(caseId), expanduser(src), dst))

  local data, rerr = read_file(src)
  if not data then return nil, "read_failed:"..tostring(rerr) end

  if cfg.reloadCursor then
    if not quit_cursor_hard(3.0) then
      print("[HS] warn: cursor still running, proceeding")
    end
    hs.timer.usleep(math.floor((cfg.delayBefore or 0.3) * 1e6))
  end

  local written_path, werr = write_file_overwrite(dst, data)
  if not written_path then return nil, werr end

  local back, berr = read_file(dst)
  if not back then return nil, "verify_read_failed:"..tostring(berr) end
  if #back ~= #data then
    return nil, string.format("verify_size_mismatch want=%d got=%d", #data, #back)
  end
  print(string.format("[HS] wrote %s bytes=%d head=%s", dst, #data, back:sub(1,80):gsub("%s+"," ")))

  if cfg.reloadCursor then
    if not launch_cursor_and_wait(cfg.delayAfter or 1.5) then
      print("[HS] warn: launch_cursor timeout")
    end
  end

  local waitExtra = tonumber(cfg.delayAfterLaunch or 5.0)
  if waitExtra > 0 then
    print(string.format("[HS] waiting %.1f s for MCP servers to initialize...", waitExtra))
    hs.timer.usleep(waitExtra * 1e6)
  end

  return true
end

local _RunCase_orig = RunCase
function RunCase(case_id, text, opts)
  opts = opts or {}
  local cfg = opts.config
  if cfg then
    local okCfg, errCfg = switch_config_for_case(case_id, cfg)
    if not okCfg then
      print("[HS] switch_config_for_case FAILED:", tostring(errCfg))
      return false, errCfg
    end
  end

  if not activate_app(2) then
    print("[HS] RunCase: cursor not active, skip this case:", case_id)
    return false, "cursor_not_active"
  end

  return _RunCase_orig(case_id, text, opts)
end