#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --job-name=sd-forge
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --gres=gpu:h100pcie:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --account=cai_teaching
#SBATCH --partition=admin
#SBATCH --output=/cluster/projects/2025_image_tools/logs/%x.id%j.%N.sbatch.out
#SBATCH --error=/cluster/projects/2025_image_tools/logs/%x.id%j.%N.sbatch.err
# #SBATCH --signal=B:SIGUSR1@900

usage() {
    cat <<EOF
Usage: $0 [-p|--port <in>] [-h|--help]

        This is a SLURM batch script for deploying the stable-diffusion forgeUI.

    Options:
        -p, --port             Port for the server.
        -h, --help             Print this message.
EOF
}


# Defaults
CU_MODULE=cuda/12.1.1
PY_MODULE=python/3.10.14
UV_MODULE=uv/0.6.12
ENV_NAME="sd-forge"  # define python virtualenv name
PKG_DIR="/cluster/projects/2025_image_tools/stable-diffusion-webui-forge"
PORT="8595"

# Parse args
OPTS=$(getopt -o he:d:o:i:n:c --long help,experiment:,env:,data-cache:,batch-size:,data-dir:,data-trunk:,out:,run-id:,run-name:,checkpoint: -- "$@")
if [ $? != 0 ] ; then
    echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - Failed to parse arguments." >&2
    exit 1
fi
eval set -- "$OPTS"

while true; do
    case "$1" in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            shift
            ;;
    esac
done
# Required arguments
if [[ $PORT -ge 8500 && $PORT -le 9100 ]]; then
    echo "Port $PORT is within the allowed range."
else
    echo "Port $PORT is outside the allowed range."
fi

# load modules
module load "$CU_MODULE"
module load "$PY_MODULE"
VENV="$ENV_NAME" module load "$UV_MODULE"
cd $PKG_DIR
mkdir -p $PKG_DIR/repositories
[ ! -d "$PKG_DIR/repositories/BLIP" ] && git clone https://github.com/salesforce/BLIP.git $PKG_DIR/repositories/BLIP && cd $PKG_DIR/repositories/BLIP && git checkout 48211a1594f1321b00f14c9f7a5b4813144b2fb9
[ ! -d "$PKG_DIR/repositories/huggingface_guess" ] && git clone https://github.com/lllyasviel/huggingface_guess.git $PKG_DIR/repositories/huggingface_guess && cd $PKG_DIR/repositories/huggingface_guesss && git checkout 84826248b49bb7ca754c73293299c4d4e23a548d
[ ! -d "$PKG_DIR/repositories/stable-diffusion-webui-assets" ] && git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets.git $PKG_DIR/repositories/stable-diffusion-webui-assets && cd $PKG_DIR/repositories/stable-diffusion-webui-assets && git checkout 6f7db241d2f8ba7457bac5ca9753331f0c266917
uv sync

# Run webui
echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - `hostname`"
uv run $PKG_DIR/webui.sh --server-name 0.0.0.0 --share --port $PORT --skip-prepare-environment
echo "[`date '+%Y-%m-%d %T.%3N'`][SLURM] - Shutdown"
