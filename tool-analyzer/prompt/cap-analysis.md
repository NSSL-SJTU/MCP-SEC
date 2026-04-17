Please analyze the provided tool JSON descriptions and determine each tool’s capabilities based on the following criteria:

1. Can **retrieve public text-based external information**, where such external information may contain potentially malicious scripts (e.g., emails, chat messages, comments, web content, etc.).
2. Can **read** sensitive or private user information, including local files, private application data, or logs.
3. Has the ability to **publish/send** data, meaning it can expose any text-based data to external networks.

Output the result in **CSV format** as follows:

```
tool_name, Capability1, Capability2, Capability3
```

Each row should represent one tool, and each capability should be marked with **“Yes”** or **“No”** only. No additional text should be included.