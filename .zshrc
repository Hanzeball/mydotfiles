# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install

# Enable auto-cd: typing a directory name changes into it
setopt AUTO_CD

# Loading Antidote (zsh plugin manager)
fpath=(${ZDOTDIR:-~}/.antidote $fpath)
autoload -Uz antidote
# End loading Antidote

# The following lines were added by compinstall
zstyle :compinstall filename '/c/Users/chpa/.zshrc'

autoload -Uz compinit
compinit -C
# End of lines added by compinstall

# Load plugins from antidote bundle
source ~/.zsh_plugins.zsh

## FuzzyFinder custom nav keybinding
export FZF_DEFAULT_OPTS="--bind 'ctrl-j:down,ctrl-k:up'"

# Enable zsh built-in vi mode
bindkey -v

# Aliases
alias vimconfig="cd ~/AppData/Local/nvim/ && nvim ."
alias zshconfig="nvim ~/.zshrc"
alias zshrs="exec zsh"
alias antidoters="antidote bundle <~/.zsh_plugins.txt> ~/.zsh_plugins.zsh && zshrs"
alias ps1="powershell -File $1"
alias ls="ls --color"
alias vinnova="cd /d/work/etjanster"

alias ga="git add $1"
alias gco="git checkout $1"
alias gconb="git checkout -b $1"
alias gst="git status"
alias gf="git fetch"
alias gfap="git fetch && git pull"
alias gp="git push"
alias gl="git pull"


# Serve e-tjanster webapps
alias serve="cd /d/work/etjanster/WebApps && pnpm install && pnpm nx serve $1"

# Open webapps root directory in VS Code
alias wa="code /d/work/etjanster/WebApps"

# Open DatbaseScript directory in VS Code
alias spraak="code /d/work/etjanster/SprakhanteringApi/SprakHantering.Repositories/DatbaseScript"

# Open DbWorkspace in VSCode
alias dbup="code /d/work/dbworkspace"

# Run Storybook
alias storybook="cd /d/work/etjanster/webapps && pnpm nx run ui:storybook"

# Search file with FuzzyFinder and open in nvim
alias find='nvim "$(fzf)"'

# dotnet cli aliases
alias dclean="dotnet clean"
alias dbuild="dotnet build"
alias drun="dotnet run --project $1"

typeset -U PATH

# Custom functions
gpsup() {
  git push --set-upstream origin $(git_current_branch)
}

# Listar alla sln filer i nuvarande mappa och alla undermappar. Måste ha Fd installerat
sln() {
	# Use fd to seach for .sln files in the current directory and all subdirectories (case-insensitive)
	local solution=$(fd -i -e sln | fzf --prompt="Select a solution: " --height=10 --border)

	# Check if any solution files were found
	if [[ -z "$solution" ]]; then
		echo "No solution file found."
		return 0
	else
		echo "Opening solution file: $solution"
		start $solution	
	fi
}

## FuzzyFinder funktion för snabbt checka ut en branch
gbl() {
  local branch
  branch=$(git branch --color=always | sed 's/^..//' | fzf --ansi --preview="git log --oneline --graph --decorate --color=always {}" --height=15 --border --exit-0)
  
  if [[ -n "$branch" ]]; then
    git checkout "$(echo "$branch" | sed 's/\x1b\[[0-9;]*m//g')"  # Strip ANSI colors
  else
    echo "No branch selected."
  fi
}

## FuzzyFinder funktion för snabbt välja en stash från git stash list
gstl() {
  local stash_entry
  stash_entry=$(git stash list --color=always | fzf --ansi --preview="git stash show -p {1}" --height=15 --border --exit-0)

  if [[ -n "$stash_entry" ]]; then
    local stash_index=$(echo "$stash_entry" | awk -F: '{print $1}')
    git stash apply "$stash_index"
  else
    echo "No stash selected."
  fi
}

## Git stash delete
gstd() {
    # Ensure we're inside a git repository
    git rev-parse --is-inside-work-tree &>/dev/null || {
        echo "Not inside a Git repository!"
        return 1
    }

    # List stash entries and let user select one
    STASH_ENTRY=$(git stash list | fzf --prompt="Select stash to delete: " --height=10 --border | awk -F: '{print $1}')
    
    # Exit if no stash is selected
    [[ -z "$STASH_ENTRY" ]] && return 0

    # Confirm deletion
    echo "Are you sure you want to delete stash '$STASH_ENTRY'? (y/N)"
    read -r CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        git stash drop "$STASH_ENTRY"
        echo "Stash '$STASH_ENTRY' deleted."
    else
        echo "Deletion cancelled."
    fi
}

## FuzzyFinder git delete branch
gbd(){
	# Ensure we're inside a git repository
	git rev-parse --is-inside-work-tree &>/dev/null || {
	    echo "Not inside a Git repository!"
	    exit 1
	}

	# List branches and let user select one
	BRANCH=$(git branch --format "%(refname:short)" | fzf --prompt="Select branch to delete: " --height=10 --border)

	# Exit if no branch is selected
	[[ -z "$BRANCH" ]] && return 0

	# Confirm deletion
	echo "Are you sure you want to delete branch '$BRANCH'? (y/N)"
	read -r CONFIRM

	if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
	    git branch -D "$BRANCH"
	    echo "Branch '$BRANCH' deleted."
	else
	    echo "Deletion cancelled."
	fi
}

gcmsg() {
    # Get the current branch name
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

    # Extract the PBI number from the branch name
    PBI_NUMBER=$(echo "$BRANCH_NAME" | grep -oE "(bugfix|pbi)/[0-9]+" | grep -oE "[0-9]+")

    # Exit if no PBI number is found
    [[ -z "$PBI_NUMBER" ]] && {
        echo "No PBI number found in branch name."
        return 1
    }

    # Prompt for commit message
    echo "Enter commit message:"
    read -r COMMIT_MSG

    # Append PBI number and commit
    git commit -m "$COMMIT_MSG #$PBI_NUMBER"
}

### Remove untracked local git branches
gprune(){
	# Fetch the latest remote branches
	git fetch --prune

	# Get a list of local branches that are no longer on remote
	stale_branches=($(git branch -vv | awk '/: gone]/{print $1}'))

	if [[ ${#stale_branches[@]} -eq 0 ]]; then
	    echo "No stale branches to remove."
	    exit 0
	fi

	# Show the branches that will be deleted
	echo "The following branches will be removed:"
	for branch in "${stale_branches[@]}"; do
	    echo -e "\e[31m- $branch\e[0m"
	done

	echo "Do you want to proceed? (y/n)"
	read -r response

	if [[ "$response" =~ ^[Yy]$ ]]; then
	    for branch in "${stale_branches[@]}"; do
		git branch -D "$branch"
	    done
	    echo "Stale branches removed."
	else
	    echo "Operation cancelled."
	fi
}


ghistory(){
	# Check if inside a git repository
	if ! git rev-parse --git-dir > /dev/null 2>&1; then
	  echo "Not inside a git repository."
	  exit 1
	fi

	# Get list of commits: "<hash> <message>"
	commits=$(git log --pretty=format:"%h %s" --date=short)

	# Use fzf to select a commit, show hash and message, copy hash on Enter
	selected=$(echo "$commits" | fzf --reverse --ansi --preview 'git show --color=always {1}' --preview-window=right:70%)

	# If a commit was selected
	if [[ -n "$selected" ]]; then
	  commit_hash=$(echo "$selected" | awk '{print $1}')

    	# Copy to clipboard using Windows clip.exe
	  if command -v clip.exe &>/dev/null; then
	    echo -n "$commit_hash" | clip.exe
	    echo "Copied $commit_hash to clipboard (Windows)"
	  else
	    echo "clip.exe not found. Clipboard copy not supported."
	    exit 1
	  fi
	fi
}


# Use OhMyPosh for prompt theming
eval "$(oh-my-posh init zsh --config ~/.mytheme.omp.toml)"
