<h1 align="center">Jovial</h1>

<p align="center">
  <img src="https://img.shields.io/badge/-macOS-greenlight?logo=Apple&logoColor=ffffff" alt="Platform macOS" />
  <img src="https://img.shields.io/badge/-WSL-greenlight?logo=windows&logoColor=ffffff" alt="Platform WSL" />
  <img src="https://img.shields.io/badge/-Debian-greenlight?logo=Debian&logoColor=ffffff" alt="Platform Debian" />
  <img src="https://img.shields.io/badge/-Ubuntu-greenlight?logo=Ubuntu&logoColor=ffffff" alt="Platform Ubuntu" />
  <img src="https://img.shields.io/badge/-CentOS-greenlight?logo=CentOS&logoColor=ffffff" alt="Platform CentOS" />
  <img src="https://img.shields.io/badge/-Arch Linux-greenlight?logo=Arch Linux&logoColor=ffffff" alt="Platform Arch Linux" />
</p>

<p align="center">
  <strong>A lovely zsh theme with responsive-design, it's simply but usefully</strong>
</p>

## Glance

<p align="center">
  <img src="./docs/jovial.png" alt="jovial" width="720">
</p>

Quick install with just a simple one-line command:

```bash
curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s $USER
```

(more details see the [Install](#install) section)



## Feature & Preview

### whole ability

As mentioned above, **jovial** theme has many useful abilities, its full display likes:

<p align="center">
  <img src="./docs/jovial-full-prompts.png" alt="jovial-full-prompts" width="900">
</p>


The description of each parts:

<p align="center">
  <img src="./docs/jovial-description.png" alt="jovial-description" style="width: 100%; max-width: 1000px">
</p>



### responsive design

Each parts of prompt is "responsive" with terminal windows width, so you can safely use it in narrow terminal.

<!-- ./docs/jovial-responsive-desigin.mp4 -->
<div><video controls muted autoplay loop src="https://user-images.githubusercontent.com/15135943/143185697-e1c612bb-d4ac-43a1-8c20-ae2a6c53e28a.mp4"></video></div>



### git actions state

In addition to the basic git state (branch / tag / hash, dirty or clean),

there are also some prompt to hint you are in **merge** / **rebase** / **cherry-pick** now with conflict or not.

<p align="center">
  <img src="./docs/jovial-git-actions.png" alt="jovial-git-actions" width="860">
</p>


### development env detecting

It will detect and show your development programming language and version in current working directory, such as:

<p align="center">
  <img src="./docs/jovial-develop-env-detect.png" alt="jovial-develop-env-detect" width="740">
</p>


## Plugins Integration

> Integrated plugins will be auto setup by install script, you can see `install.zsh-plugins` functions in [installer.sh](https://github.com/zthxxx/jovial/blob/master/installer.sh)

- **[jovial](https://github.com/zthxxx/jovial/blob/master/jovial.plugin.zsh)**: plugin defined some utils functions and alias, you can see in [jovial.plugin.zsh](https://github.com/zthxxx/jovial/blob/master/jovial.plugin.zsh)
- **[git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)**: some short alias for commonly used command
- **[autojump](https://github.com/wting/autojump)**: make you can use `j <keyword>` to jump to the full path folder
- **[bgnotify](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/bgnotify)**: background notifications for long running commands
- **[zsh-history-enquirer](https://github.com/zthxxx/zsh-history-enquirer)**: widget for history search, enhance `Ctrl+R`
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: shell auto-completion
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: user input syntax highlighting


## Install

Just run the simple one-line install command

```bash
curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s $USER
```

> **Note**: The install script is designed to be **"Idempotent"**, so you can safely execute it multiple times.

> **Tips**: you may want to use some **http proxy**, just export proxy variables before run install command,
>
> 　　like: `export all_proxy=http://127.0.0.1:1086`  
>
> 　　(it's equal to `export http_proxy=http://127.0.0.1:1086 http_proxys=http://127.0.0.1:1086`)

Here are what the install command and script do:

- explain command:
  - `sudo`: make sure script run with access for install packages and change default login shell
  - `-E`: passthrough env variables while use sudo, for receive like `http_proxy`
  - `-s $USER`: pass the params to script, which is the real target user for install

- explain script:
  - if `zsh` or `oh-my-zsh` not found, will install them
  - change default login shell to `zsh`
  - download jovial theme/plugin files in oh-my-zsh custom folder
  - install integrated plugins via local package manager
  - auto rewrite `ZSH_THEME` and `plugins` in user's `.zshrc`


### Upgrade

Due to the install script is designed to be "Idempotent", if you want to upgrade the jovial theme, run the install command again.

> Pay attention to the [migration tips](#migration)

## Customization

All the elements / symbols / colors can be easily customized by override theme variables in `.zshrc`

Those variables designed for customization: `JOVIAL_SYMBOL`, `JOVIAL_PALETTE`, `JOVIAL_DEV_ENV_DETECT_FUNCS`, `JOVIAL_PROMPT_PRIORITY`

You can find them in [jovial.zsh-theme](https://github.com/zthxxx/jovial/blob/master/jovial.zsh-theme) (`~/.oh-my-zsh/custom/themes/jovial.zsh-theme`)

### symbols

You can set variables one-by-one to override symbols, such as arrows:

```zsh
JOVIAL_SYMBOL[arrow]='->'
JOVIAL_SYMBOL[arrow.git-clean]='->'
JOVIAL_SYMBOL[arrow.git-dirty]='->'
```

Or just replace all of them:

```zsh
local -A JOVIAL_SYMBOL=(
    corner.top    '╭─'
    corner.bottom '╰─'

    git.dirty '✘✘✘'
    git.clean '✔'

    arrow '─➤'
    arrow.git-clean '(๑˃̵ᴗ˂̵)و'
    arrow.git-dirty '(ﾉ˚Д˚)ﾉ'
)
```

### development env detecting

Each item in `JOVIAL_DEV_ENV_DETECT_FUNCS` is name of function to detect development env,

you can append some custom functions for other programming language (such as Erlang), like this:

```zsh
JOVIAL_DEV_ENV_DETECT_FUNCS+=( your-function-name )
```

Or disable it by set empty list:
```zsh
local JOVIAL_DEV_ENV_DETECT_FUNCS=()
```

### colors

Override `JOVIAL_PALETTE` likes `JOVIAL_SYMBOL` above,

whole override like:

```zsh
# jovial theme colors mapping
# use `sheet:color` plugin function to see color table
local -A JOVIAL_PALETTE=(
    # hostname
    host "${FG[157]}"

    # common user name
    user "${FG[255]}"

    # only root user
    root "${terminfo[bold]}${FG[203]}"

    # current work dir path
    path "${terminfo[bold]}${FG[228]}"

    # git status info (dirty or clean / rebase / merge / cherry-pick)
    git "${FG[159]}"

    # virtual env activate prompt for python
    venv "${FG[159]}"
 
    # time tip at end-of-line
    time "${FG[254]}"

    # exit code of last command
    exit.mark "${FG[246]}"
    exit.code "${terminfo[bold]}${FG[203]}"

    # "conj.": short for "conjunction", like as, at, in, on, using
    conj. "${FG[102]}"

    # for other common case text color
    normal "${FG[253]}"

    success "${FG[040]}"
    error "${FG[203]}"
)
```

**🧐 Mess up with variables and numbers?**

Well, `${terminfo[bold]}` set font to **bold** style, 

and `${FG[]}` / `${BG[]}` is color sheet of **font** / **background**.

**🤓 So, where is the color sheet?**

You can run `sheet:color` function which in [jovial.plugin.zsh](https://github.com/zthxxx/jovial/blob/master/jovial.plugin.zsh) to display color sheet in your terminal,

it will looks like:

<p align="center">
  <img alt="color sheet" src="https://user-images.githubusercontent.com/15135943/143198898-2cf1225c-47e4-4860-95db-2dc29ad1436e.png" width="800">
</p>



## Font Recommended

- `Monaco` in iTerm2
- `Menlo` in VSCode
- `JetBrains Mono` in JetBrains IDEs

> NOTE: also remember to set font line-height to 1.0



## Benchmark

Run 10 times in benchmark.zsh:

```zsh
$ zsh -il dev/benchmark.zsh

( for i in {1..10}; do; print -P "${PROMPT}"; done; )  0.19s user 0.41s system 79% cpu 0.653 total
```

Average: **65ms** per this theme exec



## Migration

> run `echo ${JOVIAL_VERSION}` to see current version

### from v1 to v2

There are some breaking changes for customization,

some customized variables and functions renamed:

- variable `JOVIAL_ARROW` => `JOVIAL_SYMBOL[arrow]`
- function `_jov_type_tip_pointer` => `@jov.typing-pointer`,
- and now, arrows could replace with variables `JOVIAL_SYMBOL[arrow.git-clean]` and `JOVIAL_SYMBOL[arrow.git-dirty]`
- some keys in JOVIAL_PROMPT_PRIORITY renamed, `git_info` => `git-info`, `dev_env` => `dev-env`



## Author

**jovial** © [zthxxx](https://github.com/zthxxx), Released under the **[MIT](./LICENSE)** License.

> Blog [@zthxxx](https://blog.zthxxx.me) · GitHub [@zthxxx](https://github.com/zthxxx)
