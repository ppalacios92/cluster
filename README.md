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

| Command | Description |
|---|---|
| `tf` | Follow the last 50 lines of `log.log` |
| `tf <logfile>` | Follow a specific log file |
| `tf <jobid>` | Follow the `StdOut` log file of a Slurm job |
| `tf log <jobid>` | Same as `tf <jobid>` |
| `gotojob <jobid>` | Move to the `WorkDir` of a Slurm job |
| `diskjob <jobid>` | Show the disk usage of the job `WorkDir` |
| `SOS <user>` | Show and optionally cancel all Slurm jobs from a user |
| `extract <file.tar.gz>` | Extract a `.tar.gz` archive |
| `compress <folder>` | Compress a folder into `.tar.gz` in the background |


## Update

To update the tools:

```bash
cd cluster
git pull
chmod +x install.sh aliases.sh scripts/*.sh
source ~/.bashrc
```
