# DPI Engine — Deep Packet Inspection in C++17

Offline PCAP inspector: parses Ethernet → IPv4 → TCP/UDP, classifies flows via TLS SNI / HTTP Host / DNS, tracks per-flow state, enforces IP / app / domain block rules, and writes a filtered PCAP plus a terminal report. Zero dependencies — standard C++17 only.

![C++17](https://img.shields.io/badge/C%2B%2B-17-blue) ![Windows](https://img.shields.io/badge/Windows-VS2022%20%2B%20CMake-green)

## What it does

```
input.pcap → [Reader → Load Balancers → Fast Paths → Writer] → filtered.pcap + report
                  hash(5-tuple) pins each flow to one worker; workers do SNI + rule checks
```

- **Protocol parsing** — IHL / TCP data-offset aware, portable byte order (`include/platform.h`, no system headers), unaligned-safe reads.
- **Deep inspection** — TLS ClientHello SNI (ext `0x0000`), HTTP `Host`, DNS query labels, port fallback; short domains matched at label boundaries so `x.com` can't match `netflix.com`.
- **Flow tracking** — `FiveTuple → Flow` map with sticky block: once a flow classifies as blocked, every packet drops.
- **Two builds** — `dpi_engine` (threaded: Reader → LB → FP → writer via lock-based queues) and `dpi_simple` (single-threaded reference).

## Results on the sample capture

77 packets in → **71 forwarded, 6 dropped** (`--block-app YouTube --block-ip 192.168.1.50`):

```
HTTPS 39 | Unknown 16 | DNS 4 | HTTP 2 | + 16 single-app flows
www.youtube.com → YouTube | www.netflix.com → Netflix | twitter.com → Twitter/X | …
```

Sample: `samples/test_dpi.pcap` (regenerable with `py generate_test_pcap.py --seed 0 --output samples\test_dpi.pcap`).

## Run it (Windows)

Requires: Windows 10/11, [VS 2022 Build Tools](https://visualstudio.microsoft.com/downloads/) (Desktop development with C++), [CMake 3.16+](https://cmake.org/download/), Python 3.x.

```cmd
cmake -B build
cmake --build build --config Release
run.bat
```

`run.bat` runs the canonical demo. Or manually: `.\build\Release\dpi_engine.exe samples\test_dpi.pcap out.pcap --block-app YouTube --block-ip 192.168.1.50 [--lbs 2 --fps 2]`. Open `out.pcap` in Wireshark. Full setup + troubleshooting: [WINDOWS_SETUP.md](WINDOWS_SETUP.md).

## Layout

```
CMakeLists.txt            builds dpi_engine + dpi_simple (VS2022 / CMake)
include/                  pcap_reader, packet_parser, sni_extractor, types, platform
src/
  dpi_mt.cpp              ★ threaded engine (Reader → LB → FP → writer)
  main_working.cpp        ★ single-threaded reference
  pcap_reader.cpp / packet_parser.cpp / sni_extractor.cpp / types.cpp
samples/test_dpi.pcap     77-packet fixture (TLS + HTTP + DNS + blocked-IP traffic)
generate_test_pcap.py     fixture generator (--seed for reproducibility)
run.bat                   double-click demo
```

## How it works (brief)

1. **Read** — `PcapReader` validates the magic (`0xa1b2c3d4`), handles byte order, yields raw packets.
2. **Parse** — `PacketParser` walks Eth → IPv4 → TCP/UDP, computing the payload offset from header lengths.
3. **Classify** — `SNIExtractor` / `HTTPHostExtractor` / `DNSExtractor` run on the payload; `sniToAppType` maps domain → app.
4. **Enforce** — rules checked IP → port → app → domain-substring; blocked flows drop, rest serialize to the output PCAP.
5. **Report** — per-app breakdown, thread dispatch stats, detected domains.

Details: [ARCHITECTURE.md](ARCHITECTURE.md).

## Design decisions

- **Offline PCAP, not live capture** — deterministic input makes blocking behavior testable and demoable without network access.
- **Hash-pinned threading** — each five-tuple always lands on the same fast-path worker, so no cross-thread flow locking on the hot path.
- **Portable byte order, no system headers** — `include/platform.h` does its own endian handling, which is why this builds unchanged on MSVC and MinGW.
- **Label-boundary domain matching** — short domains (`x.com`, `t.co`) only match at DNS label boundaries; substring matching would misclassify `netflix.com` and `microsoft.com`.

