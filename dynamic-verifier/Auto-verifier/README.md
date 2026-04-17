# MCP Tool Auto Verifier

## Usage Guide

1. **Install Hammerspoon** on your system.

2. Place this script file in the following directory:

   ```
   ~/.hammerspoon
   ```

3. Launch the **Hammerspoon** application.

4. Open the **Hammerspoon Console**.

5. Execute the following command inside the console:

   ```
   RunSuiteFromTSV("./dataset.tsv", {
     gapAfter = 3.0,
     config = {
       dir = "./mcp_configs",
       dst = os.getenv("HOME").."/.cursor/mcp.json",
       reloadCursor = true,
       delayBefore = 1.5,
       delayAfter = 1.5,
       delayAfterLaunch = 20.0,
     },
     report = "./hs_report.json"
   })
   ```

## Parameters

- `dataset.tsv`: the user prompt dataset in TSV format.
- `config.dir`: directory containing all MCP configuration files.
- `config.dst`: destination file for the generated MCP configuration (`~/.cursor/mcp.json`).
- `reloadCursor`: whether to reload Cursor after configuration update.
- `delayBefore` / `delayAfter`: delay (in seconds) before and after each operation.
- `delayAfterLaunch`: waiting time (in seconds) after launching Cursor to ensure MCP Server is fully loaded.
- `report`: path to save the verification result in JSON format.

6. Use the SpecStory extension to capture both invoking traces and agent–chat logs.
