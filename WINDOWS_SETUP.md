# Windows Setup Guide

Canonical path: **Visual Studio 2022 + CMake**. Alternatives (MinGW, WSL) are footnotes at the bottom.

## 1. Install prerequisites

1. **VS 2022 Build Tools** (free): https://visualstudio.microsoft.com/downloads/
   - Workload: **Desktop development with C++**
2. **CMake 3.16+**: https://cmake.org/download/ (check "Add CMake to PATH")
3. **Python 3.x**: https://www.python.org/downloads/ (check "Add python.exe to PATH"; the `py` launcher works too)

## 2. Get the code and build

Open a fresh terminal (new terminal picks up PATH changes; no restart needed):

```cmd
cd /d "C:\path\to\dpi-engine"
py generate_test_pcap.py --seed 0 --output samples\test_dpi.pcap
cmake -B build
cmake --build build --config Release
```

You should now have `build\Release\dpi_engine.exe` and `build\Release\dpi_simple.exe`.

Note: if `cmake -B build` picks the wrong generator, delete the `build\` folder and retry from a
"Developer Command Prompt for VS 2022" (Start Menu), which puts `cl` on PATH.
CMake's "Visual Studio 17 2022" generator needs a full VS install; Build Tools-only machines
should rely on the default NMake generator as above.

## 3. Run

```cmd
.\build\Release\dpi_engine.exe samples\test_dpi.pcap out.pcap
.\build\Release\dpi_engine.exe samples\test_dpi.pcap out.pcap --block-app YouTube --block-ip 192.168.1.50
.\build\Release\dpi_engine.exe input.pcap output.pcap --lbs 4 --fps 4
```

Expect ~77 packets from the sample capture with an app-breakdown report.
If the box-drawing report looks garbled in `cmd`, run `chcp 65001` first (the program also
requests UTF-8 output on Windows automatically).

## 4. Real captures (optional)

1. Install Wireshark: https://www.wireshark.org/download.html
2. Capture on Wi-Fi/Ethernet for ~30s, **File -> Save As -> pcap** (not pcapng)
3. `.\build\Release\dpi_engine.exe my_capture.pcap filtered.pcap`

## Troubleshooting

| Error | Fix |
|---|---|
| `'cmake' is not recognized` | Reinstall CMake with "Add to PATH", open a NEW terminal |
| `Generator "Visual Studio 17 2022" could not find any instance` | Use a Developer Command Prompt, or just `cmake -B build` (NMake) as above |
| `'py' is not recognized` | Reinstall Python with "Add to PATH", or use `python` instead of `py` |
| `Cannot open output file` | Close whatever has `out.pcap` open, or pick a different output name |
| `std::thread` link errors (MinGW only) | Add `-pthread`; not needed for MSVC |

## Appendix: other toolchains

- **VS Code**: install the C/C++ extension, open the folder, `Ctrl+Shift+B` with a task that runs `cmake --build build --config Release`. Same commands as above.
- **MinGW-w64** (via MSYS2): `pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-make`, add `C:\msys64\mingw64\bin` to PATH, then `g++ -std=c++17 -pthread -O2 -I include -o dpi_engine.exe src/dpi_mt.cpp src/pcap_reader.cpp src/packet_parser.cpp src/sni_extractor.cpp src/types.cpp`. `-pthread` IS required here.
- **WSL**: `sudo apt install -y build-essential g++`, files at `/mnt/c/...`, same `g++ -pthread` line but output `-o dpi_engine` (no `.exe`), run with `./dpi_engine`.
- Reference: MSVC C++ docs at https://learn.microsoft.com/en-us/cpp/
