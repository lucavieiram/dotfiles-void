# ~/.zshrc — adapted from Hyprlust .zshrc with the 4 documented fixes:
#   - filename trailing-space bug removed
#   - /home/hypr/ → $HOME
#   - exa → eza (exa is deprecated)
#   - removed invalid HISTDUPE line (relies on setopt HIST_IGNORE_ALL_DUPS)
# Original credit: NischalDawadi/Hyprlust

# ========================
# >> Environment Setup
# ========================
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="nvim +Man!"
export BROWSER="brave-browser"

# PATH — order matters: local bin first, then cargo/bun/spicetify, then system
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.spicetify:/usr/local/bin:$PATH"

# Cargo env (if installed)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Per-user runit services (when using turnstile or runsvdir)
[ -d "$HOME/.config/service" ] && export SVDIR="$HOME/.config/service"

# ========================
# >> Plugins
# ========================
# Cloned by installers/gui/install.sh into ~/.zsh/
for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    src="$HOME/.zsh/${plugin}/${plugin}.zsh"
    [ -f "$src" ] && . "$src"
done

# zsh-completions adds to fpath
fpath=("$HOME/.zsh/zsh-completions/src" $fpath)

# ========================
# >> Tools Init
# ========================
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v fzf      >/dev/null && eval "$(fzf --zsh 2>/dev/null || true)"
command -v direnv   >/dev/null && eval "$(direnv hook zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && . "$HOME/.bun/_bun"

# ========================
# >> History
# ========================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ========================
# >> Completion
# ========================
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

zstyle ':completion:*' menu select
zstyle ':completion:*' file-sort date
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:paths' path-completion yes
zstyle ':completion:*:processes' command 'ps -afu $USER'

# ========================
# >> Key bindings
# ========================
bindkey -e                              # emacs mode
# Up/Down walk history (prefix-matching whatever is typed). Avoid
# `history-substring-search-*` widgets — they come from a plugin we don't
# load, and zsh silently does nothing for a missing widget (no fallback).
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[H' beginning-of-line        # Home
bindkey '^[[F' end-of-line              # End
bindkey '^[[3~' delete-char             # Delete
bindkey '^[[1;5C' forward-word          # Ctrl+Right
bindkey '^[[1;5D' backward-word         # Ctrl+Left

# ========================
# >> Appearance
# ========================
# Smoother font rendering (only relevant when launching graphical apps from terminal)
export FREETYPE_PROPERTIES="truetype:interpreter-version=35"

# FZF: gruvbox-tinted palette
export FZF_DEFAULT_OPTS='
  --color=spinner:#fabd2f,hl:#83a598
  --color=fg:#ebdbb2,header:#83a598,info:#fabd2f,pointer:#fabd2f
  --color=marker:#b8bb26,fg+:#fabd2f,prompt:#fb4934,hl+:#83a598
  --color=bg+:#3c3836,gutter:#282828
  --height=40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ========================
# >> Aliases
# ========================
# eza (modern ls)
if command -v eza >/dev/null; then
    alias ls='eza --icons --color=always --group-directories-first'
    alias ll='eza -alF --icons --color=always --group-directories-first'
    alias la='eza -a  --icons --color=always --group-directories-first'
    alias l='eza -F   --icons --color=always --group-directories-first'
    alias lt='eza --tree --level=2 --icons --color=always'
else
    alias ls='ls --color=auto'
fi

# Replace cat with bat when available
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'

# fastfetch is the maintained successor to neofetch — keep muscle memory.
command -v fastfetch >/dev/null && alias neofetch='fastfetch'

# Quick edits / nav
alias v='nvim'
alias e='$EDITOR'
alias lf='yazi'
alias g='git'
alias d='docker'
alias k='kubectl'
alias tf='terraform'
alias myip='curl -s https://api.ipify.org && echo'
alias ports='ss -tulpn'
alias path='echo $PATH | tr ":" "\n"'

# git shortcuts
alias gs='git status --short'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph -20'
alias gca='git commit --amend --no-edit'
alias gp='git pull --ff-only'

# Misc
alias pdf='soffice --headless --convert-to pdf'
alias reload='exec zsh'

# kube context shortcuts
alias kcu='kubectl config unset current-context'   # unset (hides ⎈)
alias kcs='kubectl config use-context'             # set:  kcs k3d-tcc
alias kcg='kubectl config get-contexts'            # get list

# Theme
alias dark='theme-switch.sh dark'
alias light='theme-switch.sh light'

# ========================
# >> XDG
# ========================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Make sure cache/state dirs exist
mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME"

. "$HOME/.local/share/../bin/env"
