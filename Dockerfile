# syntax=docker/dockerfile:1
FROM dlang2/dmd-ubuntu

WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/root/.dub dub build
RUN ln -s /app/myrc /usr/local/bin/myrc

ARG example_dir_1=/home/dlang/dotfiles/example1
ARG example_dir_2=/home/dlang/dotfiles/example2

USER dlang

WORKDIR $example_dir_1
COPY test .

WORKDIR $example_dir_2
RUN echo "echo wrong location 1" > wrong_location1

WORKDIR /home/dlang
RUN ln -s $example_dir_1/zshrc ~/.zshrc
RUN ln -s ./dotfiles/example1/ls_colors ~/.ls_colors
RUN ln -s $example_dir_2/wrong_location1 ~/.zshenv

WORKDIR $example_dir_1

CMD mkdir ~/.zsh && myrc && myrc install && myrc && ls -la ~
