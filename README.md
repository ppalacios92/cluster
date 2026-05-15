# Cluster Tools

Small collection of utility scripts for working on a Slurm cluster.

## Installation

Clone the repository:

```bash
git clone https://github.com/ppalacios92/cluster.git
cd cluster
```

Give execution permission to the installer:

```bash
chmod +x install.sh
```

Run the installer:

```bash
./install.sh
```

Reload your shell:

```bash
source ~/.bashrc
```

The installer adds `aliases.sh` to your `.bashrc` and gives execution permissions to all scripts.

## Available commands

### Job and file helpers

| Command | Description |
| --- | --- |
| `tf` | Follow the last 50 lines of `log.log` |
| `tf <logfile>` | Follow a specific log file |
| `tf <jobid>` | Follow the `StdOut` log file of a Slurm job |
| `tf log <jobid>` | Same as `tf <jobid>` |
| `gotojob <jobid>` | Move to the `WorkDir` of a Slurm job |
| `diskjob <jobid>` | Show the disk usage of the job `WorkDir` |
| `SOS <user>` | Show and optionally cancel all Slurm jobs from a user |
| `extract <file.tar.gz>` | Extract a `.tar.gz` archive |
| `compress <folder>` | Compress a folder into `.tar.gz` in the background |

### Cluster monitoring

All monitoring commands run as a regular user. They rely on Slurm
(`sinfo`, `scontrol`, `squeue`) and never require `sudo`.

| Command | Description |
| --- | --- |
| `cluster_status` | Full report: summary, RAM, CPU, jobs and local disks |
| `cluster_status summary` | Cluster-level aggregate (totals and percentages) |
| `cluster_status ram` | Per-node RAM table with colored usage bars |
| `cluster_status cpu` | Per-node CPU allocation and load |
| `cluster_status jobs` | Running jobs and queue summary by user |
| `cluster_status overview` | One line per node from `sinfo` |
| `cluster_status disk` | Local disks on the master plus remote disks per node (SSH) |
| `cluster_status disklocal` | Only master disks (no SSH) |
| `cluster_status diskremote` | Only remote disks on every node (SSH) |
| `cluster_status node <N>` | Detailed view of `nodeN` (Slurm info plus SSH probe) |
| `cluster_status help` | Show built-in help |
| `quick_ram` | One-line RAM summary per node (reserved vs really used) |
| `watch_cluster [N]` | Live monitor refreshing every `N` seconds (default 5) |

All commands above also have a `ladruno_` prefixed version (e.g.
`ladruno_cluster_status`, `ladruno_quick_ram`, `ladruno_watch_cluster`).

#### Concepts

The monitoring scripts distinguish between two different memory numbers,
which is important when sizing future jobs:

- **Reserved memory (RSV_MB / AllocMem)**: what Slurm has locked for running
  jobs. If a job requested `--mem=60G`, the full 60 GB is counted as
  reserved even when the job is not actually using it.
- **Free memory (FREE_MB / FreeMem)**: what the kernel reports as free.
- **USED% = (TOTAL - FREE) / TOTAL**: the real usage of the node.

A node can show 100% reserved in Slurm while only 60% of its RAM is really
in use — that indicates jobs are over-requesting memory.

The `diskremote` and `node <N>` views need passwordless SSH from the user
to the compute nodes. If SSH fails, every other view still works because
they only call Slurm.

## Update

To update the tools:

```bash
cd cluster
git pull
chmod +x install.sh aliases.sh scripts/*.sh
source ~/.bashrc
```
