# MCP-SEC Tool Analyzer

A tool framework for measuring and evaluating the security of MCP servers.

## Usage

MCP-SEC Tool Analyzer is divided into two stages, each with a corresponding executable program:

------

### Stage 1: Retrieve Server Tool Descriptions

This stage processes MCP commands and generates tool descriptions. Prepare the server configuration database (e.g., `data/data.xlsx`) and run:

```
get_description.exe input_file output_file
```

**Arguments:**

- `input_file` : Path to the input Excel file
- `output_file` : Path to the output Excel file

**Example:**

```
get_description.exe data/data.xlsx data/res.xlsx
```

------

### Stage 2: Tool Capability Analysis

This stage evaluates tool functionality and capabilities based on the descriptions from Stage 1. Run:

```
analyser.exe input [--model MODEL]
```

**Arguments:**

- `input` : Path to the input Excel file

- `--model MODEL` : Specify the model for analysis

**Example:**

```
analyser.exe data/desc.xlsx --model Claude-Sonnet-4-2025051
```
