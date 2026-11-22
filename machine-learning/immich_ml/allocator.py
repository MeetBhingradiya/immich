import ctypes
import sys

_process = None
if sys.platform != "win32":
    try:
        _process = ctypes.CDLL(None)
    except Exception:
        pass


def release() -> None:
    if _process is not None:
        if hasattr(_process, "mi_collect"):
            _process.mi_collect(True)
        elif hasattr(_process, "malloc_trim"):
            _process.malloc_trim(0)
