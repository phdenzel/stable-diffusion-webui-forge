#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH --job-name=sd-forge
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --gres=gpu:h200sxm:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --account=cai_ivs
#SBATCH --partition=gpu_top
#SBATCH --mail-user=denp@zhaw.ch
#SBATCH --output=/cluster/home/denp/logs/%x.id%j.%N.sbatch.out
#SBATCH --error=/cluster/home/denp/logs/%x.id%j.%N.sbatch.err
# #SBATCH --signal=B:SIGUSR1@900

# Defaults
PY_MODULE=python/3.10.14
UV_MODULE=uv/0.6.12
ENV_NAME="sd-forge"  # define python virtualenv name
SCRATCsH_VENVS="/scratch/venvs"
PKG_DIR="/cluster/denp/stable-diffusion-webui-forge"
DEFAULT_PORT=`showcustomports | cut -d, -f3 | xargs`
PORT=${1:-DEFAULT_PORT}

# load modules
module load "$PY_MODULE"
VENV="$ENV_NAME" module load "$UV_MODULE"
# install/sync environment
cd $HOME/$PKG_DIR
ln -sf $SCRATCH_VENVS/$ENV_NAME $PKG_DIR/venv


echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - `hostname`"

uv run bash $PKG_DIR/webui.sh --server-name 0.0.0.0 --share --port $PORT

echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - Shutdown"
