"""
Stub custom_handler.py for LiteLLM path resolution.

This file is required by LiteLLM's file-based module loading.
It imports the actual handler from the installed agentllm-core package.
"""

from agentllm.custom_handler import agno_handler

__all__ = ["agno_handler"]
