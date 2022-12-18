#!/bin/sh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/chetannaik/pidotfiles/install.sh)"
# or via wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/chetannaik/pidotfiles/install.sh)"
# or via fetch:
#   sh -c "$(fetch -o - https://raw.githubusercontent.com/chetannaik/pidotfiles/install.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/chetannaik/pidotfiles/install.sh
#   sh install.sh
#
set -e

# Make sure important variables exist if not already defined
#
# $USER is defined by login(1) which is not always executed (e.g. containers)
# POSIX: https://pubs.opengroup.org/onlinepubs/009695299/utilities/id.html
USER=${USER:-$(id -u -n)}
# $HOME is defined at the time of login, but it could be unset. If it is unset,
# a tilde by itself (~) will not be expanded to the current user's home directory.
# POSIX: https://pubs.opengroup.org/onlinepubs/009696899/basedefs/xbd_chap08.html#tag_08_03
HOME="${HOME:-$(getent passwd $USER 2>/dev/null | cut -d: -f6)}"
# macOS does not have getent, but this works even if $HOME is unset
HOME="${HOME:-$(eval echo ~$USER)}"


# Default settings
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_REPO=${ZSH_REPO:-ohmyzsh/ohmyzsh}
ZSH_REMOTE=${ZSH_REMOTE:-https://github.com/${ZSH_REPO}.git}
ZSH_BRANCH=${ZSH_BRANCH:-master}

DOTFILES="${DOTFILES:-$HOME/pidotfiles}"
DOTFILES_REPO=${DOTFILES_REPO:-chetannaik/pidotfiles}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-https://github.com/${DOTFILES_REPO}.git}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-master}


command_exists() {
  command -v "$@" >/dev/null 2>&1
}

user_can_sudo() {
  # Check if sudo is installed
  command_exists sudo || return 1
  # The following command has 3 parts:
  #
  # 1. Run `sudo` with `-v`. Does the following:
  #    • with privilege: asks for a password immediately.
  #    • without privilege: exits with error code 1 and prints the message:
  #      Sorry, user <username> may not run sudo on <hostname>
  #
  # 2. Pass `-n` to `sudo` to tell it to not ask for a password. If the
  #    password is not required, the command will finish with exit code 0.
  #    If one is required, sudo will exit with error code 1 and print the
  #    message:
  #    sudo: a password is required
  #
  # 3. Check for the words "may not run sudo" in the output to really tell
  #    whether the user has privileges or not. For that we have to make sure
  #    to run `sudo` in the default locale (with `LANG=`) so that the message
  #    stays consistent regardless of the user's locale.
  #
  ! LANG= sudo -n -v 2>&1 | grep -q "may not run sudo"
}

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() {
    true
  }
else
  is_tty() {
    false
  }
fi

# Adapted from code and information by Anton Kochkov (@XVilka)
# Source: https://gist.github.com/XVilka/8346728
supports_truecolor() {
  case "$COLORTERM" in
  truecolor|24bit) return 0 ;;
  esac

  case "$TERM" in
  iterm           |\
  tmux-truecolor  |\
  linux-truecolor |\
  xterm-truecolor |\
  screen-truecolor) return 0 ;;
  esac

  return 1
}

fmt_underline() {
  is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
  printf '%sError: %s%s\n' "${FMT_BOLD}${FMT_RED}" "$*" "$FMT_RESET" >&2
}

setup_color() {
  # Only use colors if connected to a terminal
  if ! is_tty; then
    FMT_RAINBOW=""
    FMT_RED=""
    FMT_GREEN=""
    FMT_YELLOW=""
    FMT_BLUE=""
    FMT_BOLD=""
    FMT_RESET=""
    return
  fi

  if supports_truecolor; then
    FMT_RAINBOW="
      $(printf '\033[38;2;255;0;0m')
      $(printf '\033[38;2;255;97;0m')
      $(printf '\033[38;2;247;255;0m')
      $(printf '\033[38;2;0;255;30m')
      $(printf '\033[38;2;77;0;255m')
      $(printf '\033[38;2;168;0;255m')
      $(printf '\033[38;2;245;0;172m')
    "
  else
    FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
      $(printf '\033[38;5;163m')
    "
  fi

  FMT_RED=$(printf '\033[31m')
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_BLUE=$(printf '\033[34m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RESET=$(printf '\033[0m')
}

setup_raspberrypi() {
  # Keep most recent old .zshrc at .zshrc.pre-oh-my-zsh, and older ones
  # with datestamp of installation that moved them aside, so we never actually
  # destroy a user's original zshrc
  echo "${FMT_BLUE}Updating system...${FMT_RESET}"

  # Update OS
  sudo apt update && sudo apt upgrade -y

  echo "${FMT_BLUE}Installing zsh, vim, git and tmux...${FMT_RESET}"
  sudo apt install zsh vim git tmux -y

  echo "${FMT_BLUE}Installing oh-my-zsh...${FMT_RESET}"
  setup_ohmyzsh
  setup_zshrc
  setup_shell

  # Install zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  # Install zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

  echo "${FMT_BLUE}Installing Pure prompt...${FMT_RESET}"
  mkdir -p "$HOME/.zsh"
  git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"

  echo "${FMT_BLUE}Installing fzf...${FMT_RESET}"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --bin

  echo "${FMT_BLUE}Installing Vim plugin manager...${FMT_RESET}"
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  echo "${FMT_BLUE}Installing Tmux Plugin Manager...${FMT_RESET}"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  echo
}

setup_pidotfiles() {
  # Prevent the cloned repository from having insecure permissions. Failing to do
  # so causes compinit() calls to fail with "command not found: compdef" errors
  # for users with insecure umasks (e.g., "002", allowing group writability). Note
  # that this will be ignored under Cygwin by default, as Windows ACLs take
  # precedence over umasks except for filesystems mounted with option "noacl".
  umask g-w,o-w

  echo "${FMT_BLUE}Cloning Dotfiles...${FMT_RESET}"

  command_exists git || {
    fmt_error "git is not installed"
    exit 1
  }

  # Manual clone with git config options to support git < v1.7.2
  git init --quiet "$DOTFILES" && cd "$DOTFILES" \
  && git config core.eol lf \
  && git config core.autocrlf false \
  && git config fsck.zeroPaddedFilemode ignore \
  && git config fetch.fsck.zeroPaddedFilemode ignore \
  && git config receive.fsck.zeroPaddedFilemode ignore \
  && git config pidotfiles.remote origin \
  && git config pidotfiles.branch "$DOTFILES_BRANCH" \
  && git remote add origin "$DOTFILES_REMOTE" \
  && git fetch --depth=1 origin \
  && git checkout -b "$DOTFILES_BRANCH" "origin/$DOTFILES_BRANCH" || {
    [ ! -d "$DOTFILES" ] || {
      cd -
      rm -rf "$DOTFILES" 2>/dev/null
    }
    fmt_error "git clone of pidotfiles repo failed"
    exit 1
  }
  # Exit installation directory
  cd -

  echo
}

setup_ohmyzsh() {
  # Prevent the cloned repository from having insecure permissions. Failing to do
  # so causes compinit() calls to fail with "command not found: compdef" errors
  # for users with insecure umasks (e.g., "002", allowing group writability). Note
  # that this will be ignored under Cygwin by default, as Windows ACLs take
  # precedence over umasks except for filesystems mounted with option "noacl".
  umask g-w,o-w

  echo "${FMT_BLUE}Cloning Oh My Zsh...${FMT_RESET}"

  command_exists git || {
    fmt_error "git is not installed"
    exit 1
  }

  # Manual clone with git config options to support git < v1.7.2
  git init --quiet "$ZSH" && cd "$ZSH" \
  && git config core.eol lf \
  && git config core.autocrlf false \
  && git config fsck.zeroPaddedFilemode ignore \
  && git config fetch.fsck.zeroPaddedFilemode ignore \
  && git config receive.fsck.zeroPaddedFilemode ignore \
  && git config oh-my-zsh.remote origin \
  && git config oh-my-zsh.branch "$ZSH_BRANCH" \
  && git remote add origin "$ZSH_REMOTE" \
  && git fetch --depth=1 origin \
  && git checkout -b "$ZSH_BRANCH" "origin/$ZSH_BRANCH" || {
    [ ! -d "$ZSH" ] || {
      cd -
      rm -rf "$ZSH" 2>/dev/null
    }
    fmt_error "git clone of oh-my-zsh repo failed"
    exit 1
  }
  # Exit installation directory
  cd -

  echo
}

setup_zshrc() {
  echo "${FMT_GREEN}Using the Oh My Zsh template file and adding it to ~/.zshrc.${FMT_RESET}"

  # Replace $HOME path with '$HOME' in $ZSH variable in .zshrc file
  omz=$(echo "$ZSH" | sed "s|^$HOME/|\$HOME/|")
  sed "s|^export ZSH=.*$|export ZSH=\"${omz}\"|" "$ZSH/templates/zshrc.zsh-template" > ~/.zshrc-omztemp
  mv -f ~/.zshrc-omztemp ~/.zshrc

  echo
}

setup_shell() {
  # Check if we're running on Termux
  case "$PREFIX" in
    *com.termux*) termux=true; zsh=zsh ;;
    *) termux=false ;;
  esac

  if [ "$termux" != true ]; then
    # Test for the right location of the "shells" file
    if [ -f /etc/shells ]; then
      shells_file=/etc/shells
    elif [ -f /usr/share/defaults/etc/shells ]; then # Solus OS
      shells_file=/usr/share/defaults/etc/shells
    else
      fmt_error "could not find /etc/shells file. Change your default shell manually."
      return
    fi

    # Get the path to the right zsh binary
    # 1. Use the most preceding one based on $PATH, then check that it's in the shells file
    # 2. If that fails, get a zsh path from the shells file, then check it actually exists
    if ! zsh=$(command -v zsh) || ! grep -qx "$zsh" "$shells_file"; then
      if ! zsh=$(grep '^/.*/zsh$' "$shells_file" | tail -n 1) || [ ! -f "$zsh" ]; then
        fmt_error "no zsh binary found or not present in '$shells_file'"
        fmt_error "change your default shell manually."
        return
      fi
    fi
  fi

  # We're going to change the default shell, so back up the current one
  if [ -n "$SHELL" ]; then
    echo "$SHELL" > ~/.shell.pre-oh-my-zsh
  else
    grep "^$USER:" /etc/passwd | awk -F: '{print $7}' > ~/.shell.pre-oh-my-zsh
  fi

  echo "Changing your shell to $zsh..."

  # Check if user has sudo privileges to run `chsh` with or without `sudo`
  #
  # This allows the call to succeed without password on systems where the
  # user does not have a password but does have sudo privileges, like in
  # Google Cloud Shell.
  #
  # On systems that don't have a user with passwordless sudo, the user will
  # be prompted for the password either way, so this shouldn't cause any issues.
  #
  if user_can_sudo; then
    sudo -k chsh -s "$zsh" "$USER"  # -k forces the password prompt
  else
    chsh -s "$zsh" "$USER"          # run chsh normally
  fi

  # Check if the shell change was successful
  if [ $? -ne 0 ]; then
    fmt_error "chsh command unsuccessful. Change your default shell manually."
  else
    export SHELL="$zsh"
    echo "${FMT_GREEN}Shell successfully changed to '$zsh'.${FMT_RESET}"
  fi

  echo
}

setup_configs() {
  echo "${FMT_GREEN}Adding ~/.zshrc${FMT_RESET}"
  cp -f "$HOME/pidotfiles/zshrc" "$HOME/.zshrc"

  echo "${FMT_GREEN}Adding ~/.fzf.zsh${FMT_RESET}"
  cp -f "$HOME/pidotfiles/fzf.zsh" "$HOME/.fzf.zsh"

  echo "${FMT_GREEN}Adding ~/.tmux.conf${FMT_RESET}"
  cp -f "$HOME/pidotfiles/tmux.conf" "$HOME/.tmux.conf"
  
  echo "${FMT_GREEN}Adding ~/.vimrc${FMT_RESET}"
  cp -f "$HOME/pidotfiles/vimrc" "$HOME/.vimrc"
  
  echo "${FMT_GREEN}Adding ~/.local/bin/tm${FMT_RESET}"
  mkdir -p "$HOME/.local/bin"
  cp -f "$HOME/pidotfiles/tm" "$HOME/.local/bin/tm"
  chmod +x "$HOME/.local/bin/tm"

  echo
}

main() {
  setup_color

  if [ -d "$DOTFILES" ]; then
    echo "${FMT_YELLOW}The \$DOTFILES folder already exists ($DOTFILES).${FMT_RESET}"
    echo "${FMT_YELLOW}You'll need to remove it if you want to reinstall.${FMT_RESET}"
    exit 1
  fi

  setup_raspberrypi
  setup_pidotfiles
  setup_configs

  echo "${FMT_YELLOW}Setup completed. Disconnect and connect again.${FMT_RESET}"

}

main "$@"