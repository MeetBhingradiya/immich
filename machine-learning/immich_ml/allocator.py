import ctypes
import gc
import sys

_process = None
if sys.platform != "win32":
    try:
        _process = ctypes.CDLL(None)
    except Exception:
        pass


def release() -> None:
    gc.collect()
    if sys.platform == "win32":
        try:
            # Reclaim unneeded working set physical memory on Windows
            ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
        except Exception:
            pass
    elif _process is not None:
        if hasattr(_process, "mi_collect"):
            _process.mi_collect(True)
        elif hasattr(_process, "malloc_trim"):
            _process.malloc_trim(0)
