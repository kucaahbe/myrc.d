# syntax=docker/dockerfile:1
FROM dlang2/dmd-ubuntu

COPY . /app
RUN --mount=type=cache,target=/root/.dub <<BUILD
cd /app
dub build
ln -s /app/myrc /usr/local/bin/myrc
BUILD

ARG example_dir_1=/home/dlang/dotfiles/example1
ARG example_dir_2=/home/dlang/dotfiles/example2
COPY test $example_dir_1
RUN <<EOF
mkdir -p $example_dir_2
echo "echo wrong location 1" > $example_dir_2/wrong_location1
EOF

USER dlang
WORKDIR /home/dlang

RUN <<LN
set -e
ln -s $example_dir_1/zshrc ~/.zshrc
ln -s ./dotfiles/example1/ls_colors ~/.ls_colors
ln -s $example_dir_2/wrong_location1 ~/.zshenv
LN

WORKDIR $example_dir_1
CMD mkdir ~/.zsh && myrc && myrc install && myrc && ls -la ~
