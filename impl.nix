{
  pkgs,
  variant,
  ...
}: let
  hardware_deps = with pkgs;
    if variant == "CUDA"
    then [
      cudaPackages.cudatoolkit
      linuxPackages.nvidia_x11
      xorg.libXi
      xorg.libXmu
      freeglut
      xorg.libXext
      xorg.libX11
      xorg.libXv
      xorg.libXrandr
      zlib

      # for xformers
      gcc
    ]
    else if variant == "ROCm"
    then [
      rocmPackages.rocm-runtime
      rocmPackages.hipblas
      rocmPackages.hipblaslt
      rocmPackages.hipblas-common
      rocmPackages.rocminfo
      pciutils
    ]
    else if variant == "CPU"
    then [
    ]
    else throw "You need to specify which variant you want: CPU, ROCm, or CUDA.";
in
  pkgs.mkShell rec {
    name = "forgeUI-shell";

    buildInputs = with pkgs;
      hardware_deps
      ++ [
        git
        (python313.withPackages (
          p:
            with p; [
              pip
            ]
        ))
        python313Packages.venvShellHook
        stdenv.cc.cc.lib
        stdenv.cc
        ncurses5
        binutils
        gitRepo
        gnupg
        autoconf
        curl
        procps
        gnumake
        util-linux
        m4
        unzip
        libavif
        libGLU
        libGL
        glib
      ];

    venvDir = "venv";
    packages = with pkgs;
      [
        gperf
      ]
      ++ (
        if (variant == "ROCm")
        then
          with pkgs.python313Packages; [
            torchWithRocm
            torchvision
            torchdiffeq
            torchsde
            accelerate
            bitsandbytes
            # pillow-avif-plugin
            # insightface
            # protobuf
            # pillow
            # fastapi
            # pydantic-core
          ]
        else
          with pkgs.python313Packages; [
            accelerate
            bitsandbytes
            # pillow-avif-plugin
            # insightface
            # protobuf
            # pillow
            # fastapi
            # pydantic-core
          ]
      );

    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
    HSA_OVERRIDE_GFX_VERSION =
      pkgs.lib.optionalString (variant == "ROCm")
      "11.0.2";
    # TORCH_BLAS_PREFER_HIPBLASLT =
    #   pkgs.lib.optionalString (variant == "ROCm")
    #   "0";
    CUDA_PATH =
      pkgs.lib.optionalString (variant == "CUDA")
      pkgs.cudaPackages.cudatoolkit;
    EXTRA_LDFLAGS =
      pkgs.lib.optionalString (variant == "CUDA")
      "-L${pkgs.linuxPackages.nvidia_x11}/lib";
  }
