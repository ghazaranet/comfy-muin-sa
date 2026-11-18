"""
Compatibility shim for ComfyUI on modern PyTorch / Python 3.12:
1. PyTorch custom_op schema inference for Python 3.9+ list[T] built-in generics.
2. Triton autotune guard when running without an active GPU driver (CPU fallback).
"""
import typing

# 1. PyTorch infer_schema patch
try:
    import torch._library.infer_schema as _infer_schema
    for _t in (int, float, bool, str):
        _val = _infer_schema.SUPPORTED_PARAM_TYPES.get(typing.List[_t])
        if _val:
            _infer_schema.SUPPORTED_PARAM_TYPES[list[_t]] = _val
except Exception:
    pass

# 2. Triton driver guard for CPU fallback mode
try:
    import triton.runtime.driver as _td
    try:
        _td.active.get_benchmarker()
    except RuntimeError:
        _td.active._obj = type('DummyDriver', (), {'get_benchmarker': lambda self: None})()
except Exception:
    pass
