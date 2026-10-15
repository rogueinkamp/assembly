# kvstore blueprint: the fastest, simplest key-value server in x86-64 assembly

Goal: a tiny, fast, single-binary key-value server written by hand in NASM, good enough to replace
Redis/Valkey for simple jobs, above all **holding a lock on an API object across Docker replicas**.

Ground rules
- **You write the assembly.** AI is the tutor: it explains syscalls, reviews your code, suggests
  tests. It does not write the stage for you (that's how the April aider session went in circles).
- Linux x86-64, NASM, **no libc**: raw syscalls only. Static binary; the Docker image can be `FROM scratch`.
- **Speak RESP** (the Redis protocol). Then `redis-cli`, `redis-benchmark` and every Redis client
  library (redis-py, go-redis, ioredis...) work with it unchanged. That's what makes it usable in production.
- Every stage ends with tests that pass before the next stage starts. Tests live in `tests/` and use
  Python + `redis-py` against the running binary (`pytest tests/`), so they keep working as the internals change.
- One stage = one small, reviewable commit (or a few).

Data model (deliberately small)
- Keys: byte strings (max 512 bytes).
- Values: byte strings (max 1 MB): text, JSON as a blob, or binary. Integers are just strings that
  `INCR` can parse, the way Redis does it. No lists, sets or hashes; that's what keeps it simple and fast.

---

## Stage 1: TCP server that answers one client
Write: `socket`, `setsockopt(SO_REUSEADDR)`, `bind` (127.0.0.1:6380), `listen`, `accept`, `read`, `write`, `close`.
Echo back whatever arrives.
Learn: the syscall ABI (rax = number; rdi, rsi, rdx, r10, r8, r9), `sockaddr_in` byte order (`htons`), error returns (negative rax).
Test: `nc 127.0.0.1 6380`; pytest opens a socket, sends bytes, gets the same bytes back.

## Stage 2: RESP parser + PING
Write: parse a RESP array of bulk strings (`*2\r\n$4\r\nPING\r\n...`) into an argv table of
(pointer, length) pairs inside the read buffer, without copying. Reply `+PONG\r\n`. Unknown command:
`-ERR unknown command\r\n`.
Learn: parsing decimal lengths, bounds checks on *every* read (the existing "string length bounds"
fix is the right instinct), returning a "need more bytes" result instead of crashing on a partial message.
Test: `redis-cli -p 6380 ping`; malformed input gets `-ERR` and the server stays up.

## Stage 3: Hash table: GET / SET / DEL / EXISTS
Write: an open-addressing table (linear probing, power-of-two size), FNV-1a hash, entries pointing at
key/value bytes in an arena allocated with `mmap`. Tombstones for deletes.
Learn: memory layout, `rep movsb` / `rep cmpsb` for copy and compare (this replaces the old
`simple_compare`), why power-of-two sizes make `hash & (size-1)` work.
Test: redis-py `set/get/delete/exists`, 100k random keys round-trip, binary values with `\0` and `\r\n` inside.

## Stage 4: Many clients: epoll event loop
Write: non-blocking sockets, `epoll_create1` / `epoll_ctl` / `epoll_wait`, a per-connection struct
(fd, read buffer, write buffer, offsets), handling partial reads and **pipelining** (several commands in one read).
Learn: the event-loop design Redis itself uses: single-threaded, so every command is atomic for free.
Test: 50 concurrent clients; a pipeline of 10,000 SETs then GETs; a client that sends one byte at a time.

## Stage 5: Expiry and locks (the production feature)
Write: `SET key value [NX|XX] [EX s|PX ms]`, `PEXPIRE`, `PTTL`, `TTL`. Monotonic time from
`clock_gettime(CLOCK_MONOTONIC)`. Expire lazily on access, plus a small sweep each loop tick
(sample N keys with deadlines, delete the expired ones).
Add one custom command, **`CAD key token`** (compare-and-delete: delete only if the value equals
`token`; reply 1 or 0). That's the safe lock release, and saves needing Lua scripting.
The lock recipe for Docker replicas:
- acquire: `SET lock:order:42 <random-uuid> NX PX 30000` → `OK` = you hold it, nil = someone else does
- renew: `CAE key token ms` (compare-and-expire), optional
- release: `CAD lock:order:42 <uuid>`
Test: two clients race for the same lock (exactly one wins); lock expires after PX; CAD with the wrong token does nothing.

## Stage 6: Counters
Write: `INCR`, `INCRBY`, `DECR` (parse the stored string as a 64-bit integer, add, write it back; `-ERR` if not a number).
Test: 50 clients x 1,000 INCR each = exactly 50,000.

## Stage 7: Memory that stays healthy
Write: grow the table (rehash into a 2x table) when the load factor passes ~0.7; reuse freed value
space (a simple free list by size class); a `maxmemory` limit that refuses writes with `-OOM` instead of crashing.
Test: insert/delete churn for 10 minutes with flat memory; fill to the limit and get `-OOM`, not a crash.

## Stage 8: Persistence (optional)
Write: an append-only file of the RESP commands that changed data (`SET`, `DEL`, `INCR`, expiries as
absolute times); `fsync` once a second; replay on startup. Locks usually don't need it.
Test: kill -9 during writes, restart, the data is back.

## Stage 9: Hardening
- Limits: key/value/argument count/buffer sizes; max clients; idle-client timeout.
- Fuzzing: a Python fuzzer throwing random and mutated RESP at it; AFL++ against the parser
  (a tiny harness that feeds a file to the parse routine).
- `valgrind --tool=memcheck` and `strace -c` runs; no crash on any input.
- `INFO` (keys, memory, clients, ops/sec) and `--port`, `--maxmemory` flags.

## Stage 10: Ship it
- `redis-benchmark -p 6380 -t set,get -P 16 -q` against Valkey on the same machine, numbers in the README.
- Docker: `FROM scratch`, copy the binary, `EXPOSE 6380`. Image measured in kilobytes.
- README states the guarantees honestly: single node, no replication, so a lock is exactly as reliable
  as one Redis instance (the same caveats as single-instance Redis locks).

---

Existing pieces to reuse: `server.asm` (command loop), `handle_get.asm`, `shared.inc` (move constants,
syscall numbers and struct offsets here), `GUIDE.md` (the April analysis of the current code).
Start at Stage 1 in a fresh `server.asm`; the old files are reference.
