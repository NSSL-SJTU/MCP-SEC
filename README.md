# MCP-SEC

MCP-SEC is the analysis tool of our paper:

**Mind Your Server: A Systematic Study of Parasitic Toolchain Attacks on the MCP Ecosystem**  

Accepted by **IEEE S&P 2026**

Paper: https://arxiv.org/abs/2509.06572v2

Demo website for our experiments: https://secresearcher100.github.io/

## Overview

MCP-SEC is a prototype framework for analyzing security risks in the MCP ecosystem.  
It supports two main stages of analysis:

1. **Tool capability analysis**: identifying whether MCP tools expose risk-related capabilities relevant to parasitic toolchain attacks.
2. **Dynamic verification**: testing whether these capabilities can be exercised in realistic environments through end-to-end interaction workflows.

This repository contains the core code used in our evaluation.

## Repository Structure

- `tool_analyzer/`  
  Used in the tool capability analysis.

- `dynamic-verifier/`  
  Used in the dynamic verification of tools.

## Scope

This repository is intended to provide the core experimental code and prompts used in our study.  
Some environment-specific configurations, platform credentials, or deployment-dependent components may need to be adapted before reproduction in a new environment.

## Citation

If you find this repository useful in your research, please cite our paper:

```bibtex
@article{zhao2025mind,
  title={Mind your server: A systematic study of parasitic toolchain attacks on the mcp ecosystem},
  author={Zhao, Shuli and Hou, Qinsheng and Zhan, Zihan and Wang, Yanhao and Xie, Yuchong and Guo, Yu and Chen, Libo and Li, Shenghong and Xue, Zhi},
  journal={arXiv preprint arXiv:2509.06572},
  year={2025}
}
```
