#start antigen
source $HOME/antigen.zsh

# Load the oh-my-zsh's library
antigen use oh-my-zsh

# load oh-my-zsh pluginssss
antigen bundle git
antigen bundle adb
antigen bundle colorize
antigen bundle archlinux
antigen bundle command-not-found
antigen bundle common-aliases
antigen bundle pip
antigen bundle postgres
antigen bundle pyenv
antigen bundle python
antigen bundle repo
antigen bundle ssh-agent
antigen bundle sublime
antigen bundle z

    # Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

    # Fish-like auto suggestions
antigen bundle zsh-users/zsh-autosuggestions

    # Extra zsh completions
antigen bundle zsh-users/zsh-completions

# Load the theme
antigen theme romkatv/powerlevel10k
#denysdovhan/spaceship-prompt
#ChesterYue/ohmyzsh-theme-passion 
#robbyrussell

# Tell antigen that you're done
antigen apply

# gpg variable 
export GPG_TTY=`tty`

# CCACHE 
export EDITOR=nano
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v ccache)
ccache -M 100G

