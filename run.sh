#!/usr/bin/env bash

DOCKER_IMAGE=toolbox:1.0.0
CONTAINER_NAME=toolbox

# Set environment variables
function _set_vars_env() {
  # Proxy
  [[ -f .proxy ]] && source .proxy && export {http,https,ftp}_proxy
  # ID/GID current user
  USER_ID=$(id -u)
  USER_GID=$(id -g)
  export USER_ID
  export USER_GID
}

# Install Meslo nerd font
function _install_fonts() {
  mkdir -p ~/.local/share/fonts/NerdFonts
  cp -f conf/fonts/MesloLGMNerdFont-Regular.ttf ~/.local/share/fonts/NerdFonts/MesloLGMNerdFont-Regular.ttf
}

# Build the docker arguments
_build_docker_args() {
  build_args="--build-arg http_proxy=\"${http_proxy}\" \
       --build-arg https_proxy=\"${https_proxy}\" \
       --build-arg no_proxy=\"${no_proxy}\" \
       --build-arg USER_ID=\"${USER_ID}\" \
       --build-arg USER_GID=\"${USER_GID}\""
}

# Build a docker image
function _build_docker_image() {
  local docker_file=$1
  local image_tag=$2
  local build_args=$3
  local target=$4
  local force=${5:-0}
  local command="DOCKER_BUILDKIT=1 docker build -f $docker_file -t=$image_tag $build_args"
  [[ -n $target ]] && command+=" --target=$target"
  [[ "$force" -eq 1 ]] && docker image rm "$image_tag" 2>/dev/null && command+=" --no-cache"
  command+=" ."
  image_id=$(docker images "$image_tag" --format "{{.ID}}")
  [[ -z "$image_id" ]] && echo "$command" && eval "$command"
  return 0
}

# Build the toolbox
function _build_docker_toolbox() {
  local force=0 && [[ $1 == "--force" ]] && force=1
  _build_docker_args
  _build_docker_image "Dockerfile" "$DOCKER_IMAGE" "$build_args" "" $force
}

# Build toolboox
function build_toolbox() {
  _set_vars_env
  _install_fonts
  _build_docker_toolbox "$1"
}

# Run the toolbox
function run_toolbox() {
  exec_command="/usr/bin/zsh"
  [[ -n "$1" ]] && ! [[ "$1" = "--force" ]] && exec_command=$*
  if [ "$(docker ps -a | grep -c $CONTAINER_NAME)" -gt 0 ]; then
    docker exec -it $CONTAINER_NAME bash
  else
    command="docker run --rm -it --name $CONTAINER_NAME --hostname $CONTAINER_NAME --network host --privileged"
    [[ -f .proxy ]] && command="$command --env-file .proxy"
    command="$command $DOCKER_IMAGE $exec_command"
    eval "$command"
  fi
}

if build_toolbox "$*"; then
  run_toolbox "$*";
fi

