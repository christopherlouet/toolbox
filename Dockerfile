FROM ubuntu:22.04
MAINTAINER Christopher LOUET

ARG http_proxy=""
ARG https_proxy=""
ARG no_proxy=""

ARG USER=app
ARG GROUP=app
ARG USER_ID=1000
ARG USER_GID=1000
ARG WORKDIR="/home/app"
ARG PACKAGES="sudo git openssh-client ca-certificates curl net-tools zsh dconf-cli neovim fzf bat unzip jq"

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends $PACKAGES && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Create user
RUN groupadd -g $USER_GID $GROUP && \
    useradd -g $USER_GID -u $USER_ID -s /usr/bin/zsh -d $WORKDIR $USER && \
    mkdir -p $WORKDIR/.cache && chown -R $USER:$GROUP $WORKDIR && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers

# zsh
COPY --chown=$USER:$GROUP conf/zsh/zshrc $WORKDIR/.zshrc
COPY conf/zsh/zsh-autosuggestions /usr/share/zsh-autosuggestions
COPY conf/zsh/zsh-syntax-highlighting /usr/share/zsh-syntax-highlighting

# oh-my-zsh
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git $WORKDIR/.oh-my-zsh
COPY --chown=$USER:$GROUP conf/zsh/zshrc.pre-oh-my-zsh $WORKDIR/.zshrc.pre-oh-my-zsh

# powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $WORKDIR/.oh-my-zsh/custom/themes/powerlevel10k
COPY --chown=$USER:$GROUP conf/zsh/p10k-instant-prompt-app.zsh $WORKDIR/.cache/p10k-instant-prompt-app.zsh
COPY --chown=$USER:$GROUP conf/zsh/p10k.zsh $WORKDIR/.p10k.zsh

# Set user
USER $USER
WORKDIR $WORKDIR

CMD ["/usr/bin/zsh"]

