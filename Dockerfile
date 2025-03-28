# To build: 
# this ensures we can mount directories etc without sweating with chmod and permissions
# docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg USERNAME=$USER . -t pesktux/scdino:latest
FROM continuumio/miniconda3

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    fd-find \
    fzf \
    gcc \
    git \
    jq \
    less \
    libffi-dev \
    libgomp1 \
    ncdu \
    neovim \
    python3-neovim \
    python3-py \
    snakemake \
    sudo \
    yq \
    zlib1g-dev \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*

# apt's yq is often outdated
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

ARG UID
ARG GID
ARG USERNAME
RUN addgroup --gid $GID $USERNAME
RUN adduser --uid $UID --ingroup $USERNAME $USERNAME 
USER $USERNAME
WORKDIR /home/$USERNAME

RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' && \
  git clone https://github.com/andsild/dotfiles.git && \
  ln -s ~/dotfiles/.inputrc ~/dotfiles/.gitconfig ~/dotfiles/.ipython ~/ && \
  mkdir ~/.config && ln -s ~/dotfiles/.config/nvim/ ~/.config && nvim --headless -n +'PlugInstall --sync' +qa

RUN conda create -c conda-forge -y -n docker-conda python=3.10 \
    argcomplete \
    imageio \
    ipdb \
    ipython \
    large-image \
    matplotlib \
    numba \
    numcodecs \
    numpy \
    opencv \
    openslide-python \
    pandas \
    pillow \
    pulp \
    pyyaml \
    scikit-image \
    scikit-learn \
    seaborn \
    tensorboardX \
    tifffile \
    timm \
    topometry \
    umap-learn \
    zarr 


SHELL ["conda", "run", "-n", "docker-conda", "/bin/bash", "-c"]

RUN conda install -c rapidsai -c conda-forge -c nvidia  \
    cudf cuml 'cuda-version>=12.0,<=12.8'
RUN conda install cuda-cudart cuda-version=12
# this version is without GPU, remove it
RUN conda uninstall -y pytorch

# install torch-packages with pip to get GPU versions
RUN pip install \
  # catalyst \ # removed since project seems dead and requires old python
  pytorch-ignite \
  pytorch-metric-learning \
  torch \
  torchvision
# custom packages
# RUN pip install \
#   snakemake
#   # git+https://github.com/uit-hdl/feature-inspect.git#egg=feature-inspect[all] \

# weird packages
RUN conda install -c bioconda -c conda-forge snakemake=7.20.0

RUN echo "conda activate docker-conda" > ~/.bashrc
ENV PATH /opt/conda/envs/docker-conda/bin:$PATH

# Set the entrypoint to /bin/bash
ENTRYPOINT ["/bin/bash", "--login"]
