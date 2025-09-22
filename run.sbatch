#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --job-name=sd-forge
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --account=cai_ivs
#SBATCH --partition=gpu_top
#SBATCH --mail-user=denp@zhaw.ch
#SBATCH --output=/cluster/home/denp/logs/%x.id%j.%N.sbatch.out
#SBATCH --error=/cluster/home/denp/logs/%x.id%j.%N.sbatch.err
# #SBATCH --signal=B:SIGUSR1@900

# Defaults
CU_MODULE=cuda/12.1.1
PY_MODULE=python/3.10.14
UV_MODULE=uv/0.6.12
ENV_NAME="sd-forge"  # define python virtualenv name
PKG_DIR="/cluster/home/denp/stable-diffusion-webui-forge"
PORT=8622

# load modules
module load "$CU_MODULE"
module load "$PY_MODULE"
VENV="$ENV_NAME" module load "$UV_MODULE"
cd $PKG_DIR
uv sync

# Run webui
echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - `hostname`"
uv run $PKG_DIR/webui.sh --server-name 0.0.0.0 --share --port $PORT --skip-prepare-environment
echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - Shutdown"
