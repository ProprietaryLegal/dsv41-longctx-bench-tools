# DeepSeek-V4.1-Flash on DGX Spark / GB10 and x86: long-context, prefix-identity and RDMA benchmark tools

Measure request timing, speculative decoding, concurrent long prompts and direct-link interference in a system with two DGX Spark (GB10) nodes and an x86 offload host with RTX 3090s. Needle and prefix-identity checks help distinguish retrieval failures, cross-request contamination and prefix-cache behavior. These are source tools; no corpus or raw benchmark records ship here.

**Hugging Face:** [Card and files](https://huggingface.co/ProprietaryLegal/dsv41-longctx-bench-tools) · **Stack overview:** [GitHub](https://github.com/ProprietaryLegal/DeepSeek-V4.1-Flash-2xDGX-Spark-x86-offload) · **Collection:** [All entries](https://huggingface.co/collections/ProprietaryLegal/deepseek-v41-flash-on-2x-dgx-spark-x86-offload-6adab604a517b426ded3916e)

<!-- pli:blurb:start -->

> Published by [PLI Labs](https://proprietarylegal.ai/labs.html), the open research arm of [Proprietary Legal Intelligence](https://proprietarylegal.ai). PLI builds AI systems around a legal organization's own work product, combining retrieval, staged workflows, validation, and attorney review. Visit [proprietarylegal.ai](https://proprietarylegal.ai) to explore our work and discuss what your organization needs.

<!-- pli:blurb:end -->

<!-- pli:update:2026-10-27:start -->

**Update 2026-10-27:** the full DSV41 source is now public — [dsv41-offload](https://github.com/ProprietaryLegal/dsv41-offload) (every component; `production`, `main` and per-experiment `lane/*` branches), with focused repos for the [measurement harness](https://github.com/ProprietaryLegal/dsv41-window-harness) and [sampled drafting](https://github.com/ProprietaryLegal/dsv41-sampled-drafting). Status and lessons: [2026-10-27 post](https://github.com/ProprietaryLegal/pli-labs/blob/main/research/dgx-spark-offload/2026-10-27-status-and-code.md).

<!-- pli:update:2026-10-27:end -->

<!-- pli:update:2026-10-28:start -->

**Update 2026-10-28:** the workload instructions and the synthetic-record vocabulary of `code/bench.py` and `code/bench/bench2.py` are no longer in the code. Put them in a JSON file with the keys `workloads`, `first`, `last`, `places`, `verbs`, `claims` and `paragraph` (format in the header of `code/bench/bench2.py`) and name it in `DSV41_BENCH_SPEC_FILE`. The drivers and their output are otherwise unchanged.

<!-- pli:update:2026-10-28:end -->


## Status

2026-10-23 — research-only tools in use: request timing and link-load tools produced the published comparisons; the needle and prefix-identity tools are available for qualification, with no unfinished packing or extended-context result claimed here.

Some shell drivers and link/observation helpers retain deployment-specific paths and topology. Direct Python benchmark, needle and prefix commands below use the published layout. Configure the topology-dependent helpers before use.

## What it is

The main benchmark sends matched prompts to an OpenAI-compatible server and records TTFT, first visible answer, reasoning/answer accounting, delivered tokens, speculative counters, per-stream rate, aggregate rate and task time. It records the gaps between content-bearing SSE events as a direct client-side step timer when the serving implementation emits an event per step. That correspondence is an engine-specific observation; buffered streams need separate validation.

Cold groups use fresh salts with identical workload text. Warm groups reuse salts and label the first priming run cold. Concurrent groups start together. A mixed case starts decoding streams before introducing a long prefill and refuses to claim overlap if those streams have already finished.

Needle checks build haystacks from **public CourtListener opinion and RECAP text that you supply yourself**. Both `opinions_cl.jsonl` and `filings_recap.jsonl` are read. No corpus ships with the repo. Each JSONL document needs `text`; `title`, `court` and `date` are optional display fields. Do not copy private matter records into a public benchmark package.

## Why

Advertised context limits do not establish occupied-context capacity. A high delivered-token rate can also hide changed draft acceptance, cache reuse or different output budgets. These tools retain the settings and accounting needed for matched comparisons, while targeted retrieval/cache checks test different failure modes.

## When to use it

Use it in a reserved benchmark window with fixed model, workload, salts/cache policy, sampling, output budget and hardware. Inspect failed rows and actual occupied prompt counts. Use retrieval and cache checks alongside timing when changing cache layout or scheduling.

## When not to use it

Do not treat an advertised maximum, dry-run build, successful fixture test or needle score as general model quality or long-context capacity. Do not run the worker-stop drill against an active service outside a planned failure test. A loaded-link benchmark changes traffic and needs an isolated measurement window.

## Requirements

- Python standard library for request, needle, prefix and link-controller tools.
- An OpenAI-compatible `/v1/models` and `/v1/chat/completions` service; the main benchmark also uses `/tokenize` and `/metrics`. Prefix checks require cache-token usage and meaningful token logprobs. Validate that logprob arrays are populated before interpreting the verdict.
- Your own sufficient public corpus in the JSONL schema above. Needle/prefix dry runs still load it. Their dry-run token counts are estimates; live commands use the server tokenizer and retain reported usage where available.
- SSH access for benchmark telemetry and link helpers. Configure `spark-a`, `spark-b` and `x86-host` aliases, NICs, metrics endpoints and GPU selectors in your own environment. The sample x86 GPU selectors are placeholders.
- Link helpers need perftest, libibverbs tools and, for cross-checks, iperf3 on the measured hosts. The tested setup used ConnectX-7 / ConnectX-5 Ex with 40 Gb/s links and Ethernet MTU 9000.
- CPU-only NIC-loopback experiments need a separately built ofl library/header from the transport repository. That dependency is absent from this source copy. Passive observation additionally needs sysstat tools and read access to the relevant process/system counters.

## Measured effect

These are our earlier measured outcomes, retained from the live card with explicit scope. The main serving comparisons used the public [EXL3 2.75 bpw target](https://huggingface.co/ProprietaryLegal/DeepSeek-V4.1-Flash-1017-EXL3-2.75bpw-LegalWeighted-DGX-Spark), two GB10 nodes in TP2, remote Engram and a synchronous one-card RTX 3090 drafter unless the worker comparison says otherwise. Thinking high, temperature 1 and top_p 1 were matched. No new model or link measurements were taken for this documentation update. Dates below are UTC. The current production stack uses async rounds through a process proxy with the one-card worker; these historical tests used synchronous rounds.

All rows ran on 2026-10-23 on the hardware and model above at concurrency 1. Each loaded-link row is one request compared with unloaded repeats; requested and achieved load rates are per link, with both links loaded toward the Sparks. The drill is one request. The worker comparison has 3 repeats per worker and workload group.

| Test / context / differing conditions | Finding |
|---|---|
| Cold 32K; requested 10 Gb/s, achieved 9.93 Gb/s/link | TTFT 14.59 s, +0.3 %; direct step p50 42.8 ms, +1–2 %; close to baseline noise |
| Cold 32K; requested 35 Gb/s, achieved 34.71 Gb/s/link | TTFT 14.91 vs 14.55 s, +2.5 %; step p50 42.6 ms, +1 % |
| Cold 150K; requested 35 Gb/s, achieved 34.67 Gb/s/link; load covers 60 s of prefill | TTFT 70.31 vs 68.88 s, +2.1 % |
| Short prompt, 6,000-token output budget; worker stopped/restarted | Request completed; drafted step p50 39.6 ms → target-only 27.7 ms → drafting resumed; 4,758 tokens, normal stop |
| Short and 32K; physical two-RTX-3090 NVLink worker vs one card on the same running serve | Direct step p50 improved −2.5 % per round in both workload groups |

The historical “about two percent” interference finding is a small TTFT cost near link saturation, not a new model-throughput improvement. The failure drill demonstrates continued answering and reconnect, not unchanged quality or zero recovery delay. The worker comparison uses the direct event-gap timer; the lower target-only step time produces fewer tokens per step and is not itself a throughput win.

## Upstream claims

Not applicable. The tables above are our measurements. No upstream KV-packing capacity, prefix-restore speed or extended-context claim is adopted as a result of these tools. The included cache checks are tests to run, not evidence that a particular optimization passed.

## Deploy

Run commands from the standalone repository root. Save generated results outside the source tree. Configure telemetry selectors and host aliases before a live benchmark; `--dry-run` still reads telemetry over SSH.

The main request benchmark takes URL, corpus, contexts, workload, concurrency, repetitions, cache mode and sampling flags. It writes request/run JSONL plus settings and raw telemetry:

```bash
python code/bench/bench2.py --url http://SPARK:8000 --dry-run \
  --spark-hosts spark-a spark-b --x86host-host x86-host \
  --out /data/results/connectivity.jsonl
python code/bench/bench2.py --url http://SPARK:8000 --label baseline \
  --ctx 32000 150000 --workload summary --data-dir /data/public-corpus \
  --concurrency 1 2 3 --reps 3 --max-tokens 1500 --thinking \
  --reasoning-effort high --temperature 1 --top-p 1 --priority 10 \
  --cache-mode cold --spark-hosts spark-a spark-b --x86host-host x86-host \
  --out /data/results/baseline.jsonl
python code/bench/report.py /data/results/baseline.jsonl \
  /data/results/candidate.jsonl --out /data/results/comparison.md
python code/bench/summ.py /data/results/baseline.jsonl
```

For a warm comparison, use `--cache-mode warm` and enough repetitions to separate priming from warm reuse. `--mixed --mixed-short-ctx 8000` adds a long-prefill arrival during active decoding. Keep parameters equal across variants.

| Request / report tool | Inputs and outputs | Exit behavior |
|---|---|---|
| `code/bench/bench2.py` | CLI above; streaming API, metrics and telemetry → request/run JSONL, settings, prompt hashes, usage and event gaps | 0 on successful execution; 1 on unhandled runtime/measurement failure; 2 for parser validation errors. Failed groups are recorded before raising |
| `code/bench/report.py` | Benchmark JSONL paths → Markdown table/stdout and optional `--out` | 0 when report builds, even with recorded failed runs; 1 on invalid JSON, duplicates or missing request records; 2 on CLI errors |
| `code/bench/summ.py` | Positional JSONL files → compact stdout view of requests, counters, event gaps and errors | 0 when readable; 1 on malformed/unreadable input. No performance pass/fail gate |
| `code/bench/telemetry.py` | Imported sampler configured through benchmark flags → raw SSH observations and error records | Library helper, no standalone CLI/exit contract; missing data is recorded, not a healthy observation |
| `code/bench.py` | Original single-stream driver; configure URL/model/node constants and local corpus path; context/workload/repeats/output flags → legacy JSONL and stdout | Caught generation failures can still yield exit 0 with `error` rows; nonzero on uncaught setup/file failures. Prefer the extended driver |

The original driver has no `--url` option. After configuring its constants and creating the output directory, its published-layout invocation is:

```bash
python code/bench.py --ctx 0 --workload prose --reps 3 \
  --max-tokens 1500 --out /data/results/original.jsonl
```

| Suite helper | Inputs and outputs | Exit behavior / preparation |
|---|---|---|
| `code/bench/suite.sh` | Label, URL, output directory, optional stage names → staged benchmark JSONL | Stops on driver failure; 2 for unknown stage. Rebase its embedded driver path to the standalone layout first |
| `code/bench/compact.sh` | Label, URL, output directory → matched short/long and concurrent JSONL | Stops on command failure; retains the same deployment-path dependency |
| `code/bench/drill_worker.sh` | Label, URL, output directory, optional stop delay and downtime → request JSONL, before/down/after counters, event timestamps | Stops/restarts a configured remote worker through systemd; nonzero on failed commands/request. Requires planned downtime, configured service/hosts and rebased driver path |

The suite contains short, cold/warm long-context, mixed, full-output and capacity stages. The commands above show the direct standalone driver equivalent. Conditional helper syntax, after rebasing paths, is `bash code/bench/suite.sh LABEL http://SPARK:8000 /data/results/suite short c32` and `bash code/bench/compact.sh LABEL http://SPARK:8000 /data/results/compact`. The drill syntax is `bash code/bench/drill_worker.sh LABEL http://SPARK:8000 /data/results/drill`; it is an active failure test, not a connectivity probe.

Needle inputs are target context, needle count, concurrent haystacks, seeds, repetitions, corpus and URL. Output is appended score/usage/latency JSONL, recall and foreign-code detection. Live requests disable thinking and use greedy sampling. Each request gets distinct seeded codes; a foreign code belongs to another request in the same wave.

```bash
python code/kvpack/needle.py --dry-run --ctx 8000 \
  --data-dir /data/public-corpus --out /data/results/needle-dry.jsonl
python code/kvpack/needle.py --url http://SPARK:8000 --ctx 32000 \
  --needles 6 --concurrent 4 --reps 1 --data-dir /data/public-corpus \
  --out /data/results/needle.jsonl
```

`needle.py` exits 1 if any request misses the configured `--min-recall` fraction or returns a foreign code; the default threshold is 1.0. Exit 0 means the selected score checks passed. Invalid CLI syntax exits 2; runtime/corpus/network failures are nonzero. A dry run scores generated expected answers and tests no model. Context is a requested text budget, not a guarantee of exact occupied chat length; inspect server usage and reserve output space yourself.

Prefix identity compares cold, cache-hit and fresh-salt controls using token output, chosen/top logprobs and reported cached tokens. It also supports partial shared prefixes and an A–filler–A eviction sequence:

```bash
python code/kvpack/prefix_identity.py --dry-run --n 8000 \
  --data-dir /data/public-corpus
python code/kvpack/prefix_identity.py --url http://SPARK:8000 \
  --block 128 --n 32000 --partial 32000:16000 \
  --data-dir /data/public-corpus --out /data/results/prefix.jsonl
python code/kvpack/prefix_identity.py --url http://SPARK:8000 \
  --block 128 --order ABA --n 32000 --fillers 2 \
  --data-dir /data/public-corpus --out /data/results/prefix-eviction.jsonl
```

Choose `--block` for the actual engine cache layout; the example is the baseline layout, not a packing result. Full-hit counts are computed from actual prompt usage, reserving the final prompt token. Partial checks use chat tokenization for the common prefix when available, otherwise bounds. Every fresh-salt control, and the first A in eviction mode, must report zero cached tokens.

Prefix output rows contain `PASS`, `FLAG` or `FAIL`, observed/expected cache counts, divergence/floor diagnostics and metrics deltas. **Exit 1 means a FAIL, usually wrong cache accounting. FLAG does not make the process fail:** it means output drift exceeds the measured cold-control floor and needs comparison with the same baseline row. Exit 0 can therefore include FLAG. Parser errors exit 2; runtime errors are nonzero. Dry run performs local self-checks and estimated corpus construction, with no server calls and no result JSONL.

Configure the link map, direct addresses, ready-marker check and metrics URL in the link helpers first. These settings are currently deployment-specific. Then the published-layout entry points are:

```bash
python code/bench/s1_links.py --link both --simultaneous \
  --out /data/results/links
bash code/bench/link_load.sh --link both --seconds 10 \
  --rate-gbps 5 --size 77824 --during-benchmark
```

The load command requires verified idle startup; the explicit overlap option permits subsequent requests. Without it, new or unverified activity stops traffic. Rate is requested per link, and achieved rates must be read from the output.

| Link / observation tool | Inputs and outputs | Exit behavior |
|---|---|---|
| `code/bench/link_load.sh`, `code/bench/s1_load.py` | Link, rate, duration, payload, direction and configured metrics selection → JSON with commands, actual rates, errors and owned-peer exits | 0 on measured success; 1 for failed/missing measurements; 2 for invalid options. Wrapper propagates Python exit |
| `code/bench/s1_links.py` | Link, RDMA/TCP/iperf mode, simultaneous/resume and output directory → append-only result files | Nonzero on failed matrix case, unavailable idle proof, topology/ready-marker errors; 2 for CLI errors |
| `code/bench/s1_tcp.py` | Positional role, bind IP, peer IP, port, payload bytes, count, mode, optional start timestamp → JSON TCP latency/rate | 0 on complete exchange; 1 on socket/payload/handshake failure; 2 on CLI errors. Usually invoked by the link controller |
| `code/bench/s1_inventory.py` | Configured SSH hosts, no CLI parameters → per-host inventory JSONL and stdout statuses | Top-level 0 does not imply each remote command succeeded: inspect saved `returncode`; exceptions are nonzero. Configure output directory before invocation |
| `code/bench/s1_report.py` | Fixed result-directory constant, no CLI parameters → link tables and retained failures | 0 can include pending/failed cases; 1 on parsing/I/O errors. Configure its input directory to match your result location |
| `code/bench/s1_finish.py` | Original topology, progress path and resumable stage list → checkpoints and matrix outputs | Deployment-specific legacy resume driver; waits for readiness, stops on real test errors. Reconfigure all paths before use; it is not a generic benchmark command |
| `code/roundtrip/ofl_loopback.cpp` | `PORT ITERS PERIOD_US SPIN_US CLIENT_CPU SERVER_CPU` → CPU NIC-loopback JSONL | 0 when all marker/generation/length checks pass; 1 on argument, connection or correctness failure. Requires external ofl header/library and configured bind address |
| `code/roundtrip/run_x86host.sh` | Configured working directory/NIC loopback binary → burst/paced/poll/event JSONL, stderr and completion marker | Stops on error; configure its fixed directory/address first |
| `code/roundtrip/observe_x86host.sh` | Output directory and optional duration → passive CPU/thread/IRQ/GPU/memory snapshots | 2 for invalid duration, 3 unless exactly one worker matches, 4 unless both NICs match; other failed commands nonzero. Configure worker matcher and NIC discovery first |

Conditional helper examples are `python code/bench/s1_inventory.py`, `python code/bench/s1_report.py` and `python code/bench/s1_finish.py` after their paths/topology are configured. The TCP probe's server syntax is `python code/bench/s1_tcp.py server LOCAL_DIRECT_IP PEER_DIRECT_IP PORT BYTES COUNT echo`; run a matching client on the peer. These are active sockets; their controller normally supplies both ends.

Build the loopback tool against the external transport, after setting its bind address for the x86 NIC:

```bash
g++ -std=c++17 -O3 -Wall -Wextra -Werror -pthread \
  -I /data/ofl -L /data/ofl -Wl,-rpath,/data/ofl \
  code/roundtrip/ofl_loopback.cpp -lofl -o /data/tools/ofl_loopback
/data/tools/ofl_loopback 18671 300 0 2000000 -1 -1
bash code/roundtrip/observe_x86host.sh /data/results/passive 45
```

NIC loopback traverses no cable and opens no model/GPU context. Passive sampling sends no inference request or affinity change. The observation helper's worker regex is deployment-specific and must be corrected before expecting it to find your process. The loopback wrapper can be invoked as `bash code/roundtrip/run_x86host.sh` after configuring its fixed workspace.

## Rollback

Stop your benchmark client and its owned traffic generators. The link controller supervises only its own peer processes and closes them when aborted. Restore a worker stopped by a planned drill using the matching configured service and verify it is healthy. These tools do not otherwise change the model or network configuration. Retain failed result rows for diagnosis; do not merge them into successful means.

## Limits and known issues

- Server speculation metrics are global. Unrelated requests contaminate acceptance deltas; the idle gate alone does not reserve the whole run.
- Exact delivered totals come from server usage. Per-channel counts may be explicitly labelled retokenized text and need not recover original generation token IDs. Rejected draft proposals are not delivered tokens.
- SSE event gaps measure client arrival intervals. Validate event/engine-step correspondence and buffering before calling them device step time.
- Aggregate throughput includes prefill and group wall time; per-stream decode uses a different interval. A short output that reaches its budget has not completed a whole task.
- Fixture tests measure software behavior, not model throughput. A report can build successfully while showing failed or missing measurements.
- Needle/prefix tools require your corpus even in dry runs. They do not establish exact occupied context or include a broad model-quality evaluation. Prefix `FLAG` requires manual review, and logprob support must be checked.
- In ABA mode, the cache verdict checks a non-null, block-aligned count but does not enforce the displayed upper bound or require eviction. Inspect the cache counts and `evicted` flag separately.
- The shell suite/compact/drill drivers still assume an `offload/bench` path. Link/report/resume helpers, telemetry selectors and passive observation retain fixed deployment settings. The loopback transport dependency is external. These are known standalone packaging limits.

## Repository layout

| Path | Purpose |
|---|---|
| [code/bench.py](code/bench.py) | Preserved original single-stream benchmark |
| [code/bench/bench2.py](code/bench/bench2.py), [telemetry](code/bench/telemetry.py) | Matched concurrent/mixed streaming benchmark and raw hardware sampler |
| [report](code/bench/report.py), [quick view](code/bench/summ.py) | Repeat tables and per-run diagnostics |
| [suite](code/bench/suite.sh), [compact](code/bench/compact.sh), [failure drill](code/bench/drill_worker.sh) | Deployment-specific benchmark stage drivers |
| [link controller](code/bench/s1_links.py), [load driver](code/bench/s1_load.py), [wrapper](code/bench/link_load.sh), [TCP probe](code/bench/s1_tcp.py) | Direct-link measurements and paced interference |
| [inventory](code/bench/s1_inventory.py), [link report](code/bench/s1_report.py), [resume driver](code/bench/s1_finish.py) | Topology snapshots and original link-workflow helpers |
| [code/kvpack/needle.py](code/kvpack/needle.py) | Public-text haystack recall and foreign-code scoring |
| [code/kvpack/prefix_identity.py](code/kvpack/prefix_identity.py) | Cold/hit/control, partial-prefix and eviction checks |
| [code/roundtrip](code/roundtrip) | CPU-only NIC-loopback experiment and passive x86 observation |
| [benchmark tests](code/bench/test_bench2.py), [link safety tests](code/bench/test_s1_links.py) | Mocked CPU regression checks |

## Tests

From the standalone root:

```bash
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover \
  -s code/bench -p 'test_*.py' -v
```

The earlier standalone publication recorded 20 passed. The independent documentation check reran the same published suite: **20 passed**. Tests mock model requests, telemetry and link traffic; no inference, SSH, NIC load or GPU work was performed. They cover stream/accounting errors, settings, actual fixture concurrency, duplicate records, idle refusal and owned-peer cleanup. The needle and prefix dry-run commands above additionally require your corpus; they are not included in that unit-test count.

## Credits and licences

PLI Labs tools are Apache-2.0. There are no vendored third-party files, model weights or upstream patch sets in this package; see [NOTICE](NOTICE) and the full [Apache-2.0 text](LICENSES/Apache-2.0.txt). DeepSeek supplies the model, HeNryous and sudoingX the serving-image/recipe lineage, vLLM the serving/metrics interface, and turboderp/exllamav3 the quantized runtime used in the measured system. CourtListener supplies the public source text users obtain separately. perftest, rdma-core, iperf3 and ofl are external tools/dependencies.

## Related

| Entry | GitHub | Hugging Face |
|---|---|---|
| Async host-flag handoff | [Source](https://github.com/ProprietaryLegal/dsv41-async-hostflag-handoff) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-async-hostflag-handoff) |
| Remote RTX 3090 drafter | [Source](https://github.com/ProprietaryLegal/dsv41-remote-dspark-drafter-3090) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-remote-dspark-drafter-3090) |
| NVLink drafter | [Source](https://github.com/ProprietaryLegal/dsv41-dspark-drafter-tp2-nvlink) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-dspark-drafter-tp2-nvlink) |
| Remote Engram | [Source](https://github.com/ProprietaryLegal/dsv41-remote-engram-rdma) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-remote-engram-rdma) |
| ofl transport | [Source](https://github.com/ProprietaryLegal/ofl-rdma-transport) | [Card](https://huggingface.co/ProprietaryLegal/ofl-rdma-transport) |
| Native SM86 drafter | [Source](https://github.com/ProprietaryLegal/dsv41-native-1017-drafter-sm86) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-native-1017-drafter-sm86) |
| Exact acceptance ceiling | [Source](https://github.com/ProprietaryLegal/dsv41-exact-acceptance-ceiling) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-exact-acceptance-ceiling) |
| Full stack overview | [Source](https://github.com/ProprietaryLegal/DeepSeek-V4.1-Flash-2xDGX-Spark-x86-offload) | [Card](https://huggingface.co/ProprietaryLegal/DeepSeek-V4.1-Flash-2xDGX-Spark-x86-offload) |
| Offload findings | [Source](https://github.com/ProprietaryLegal/dsv41-spark-offload-findings) | [Card](https://huggingface.co/ProprietaryLegal/dsv41-spark-offload-findings) |

Upstream forks: [HeNryous lineage](https://github.com/ProprietaryLegal/deepseek-v41-1017-dgx-spark) · [sudoingX lineage](https://github.com/ProprietaryLegal/dgx-spark-deepseek-v41).

[Collection](https://huggingface.co/collections/ProprietaryLegal/deepseek-v41-flash-on-2x-dgx-spark-x86-offload-6adab604a517b426ded3916e) · [Hub](https://github.com/ProprietaryLegal/pli-labs/tree/main/research/dgx-spark-offload).

<!-- pli:footer:start -->

---

## About PLI Labs

“Your proprietary work product is your proprietary intelligence.” PLI Labs is the open research arm of Proprietary Legal Intelligence. We publish legal model prunes, serving recipes for owned hardware, and open-source tools so readers can inspect our methods and test our claims before hiring us.

Founded by a practicing trial lawyer, PLI builds AI systems around a legal organization's own work product: retrieval, staged workflows, validation, and attorney review. The approach grew from systems running on live matters in a litigation practice. Our consulting work supports deployment through approved frontier APIs, private cloud, or open-weight models on hardware you own. Explore the research or contact us about your organization's work.

[Website](https://proprietarylegal.ai) · [PLI Labs](https://proprietarylegal.ai/labs.html) · [Research](https://proprietarylegal.ai/research/index.html) · [GitHub](https://github.com/ProprietaryLegal) · [Hugging Face](https://huggingface.co/ProprietaryLegal) · [Contact](https://proprietarylegal.ai/contact.html)

Proprietary Legal Intelligence LLC is a technology consultancy, not a law firm, and does not provide legal services or legal advice.

<!-- pli:footer:end -->
