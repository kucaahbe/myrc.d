# myrc

Symlinking CLI tool for dotfiles (or any other configuration files organized in a directory).

## Usage

In the directory from where the app is started, the `install.sdl` manifest file is required: there should be specified
folder installation details:

```
# the "install" section is mandatory
install {
  # executes specified commands, unless requirements below met
  exec "git submodule -q update --init" {
    # requirements:
    // file should be created in $PWD
    creates:file `LS_COLORS/.git`
    creates:file `zsh-completions/.git`
    creates:file `zsh-syntax-highlighting/.git`
  }

  ln "bashrc", "~/.bashrc"
  ln "bash_profile", "~/.bash_profile"
}
```

Without arguments - shows current state:
```console
me@host:~/doftiles$ myrc
/home/me/dotfiles:
+ /home/me/dotfiles/bashrc -> /home/me/.bashrc
- /home/me/dotfiles/bash_profile # no such file or directory (need -> /home/me/.bash_profile)
```

The `install` sub-command issues the install process:
```console
me@host:~/doftiles$ myrc
/home/me/dotfiles install:
  /home/me/dotfiles/bashrc -> /home/me/.bashrc
  /home/me/dotfiles/bash_profile -> /home/me/.bash_profile
```

## Install

| Operating system | Link |
|---|---|
| Ubuntu 22.04 (Jammy Jellyfish) | [:arrow_upper_right:](https://github.com/kucaahbe/myrc.d/releases/latest) |
| Ubuntu 20.04 (Focal Fossa) |  [:arrow_upper_right:](https://github.com/kucaahbe/myrc.d/releases/latest) |
| macOS | [:arrow_upper_right:](https://github.com/kucaahbe/myrc.d/releases/latest) |

### Build

Install [D compiler](https://dlang.org/download.html), `cd` into directory and run `dub`:

```console
dub build --build=release
```

#### Build issues

[documented here](build_issues.md)
