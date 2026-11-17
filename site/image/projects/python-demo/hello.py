import platform
import sys

name = sys.argv[1] if len(sys.argv) > 1 else "world"
print(f"Hello, {name}! Welcome to jovial.")
print(f"Python {platform.python_version()} · {platform.machine()}")
