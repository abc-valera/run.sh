#!/bin/bash

# bash completion for the run task runner
# Learn more: https://run.jotaen.net
#
# Prerequisites:
#	make sure that the bash-completion tool is configured correctly:
#	https://github.com/scop/bash-completion
#
# Installation:
#	put this file (under the name 'run') in the completions subdir
#	of "$BASH_COMPLETION_USER_DIR", which defaults to
#	"$XDG_DATA_HOME"/bash-completion or ~/.local/share/bash-completion
#	if $XDG_DATA_HOME is not set, to have them loaded automatically.

OPTS="-f --file -i --info -l --list --ls -h --help --version"

_run_completion() {
	# Get the current and previous words
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"

	# Determine which task file to use based on the --file option
	local task_file="./run.sh"
	for ((i = 1; i < COMP_CWORD; i++)); do
		local word="${COMP_WORDS[$i]}"
		case "$word" in
		-f | --file)
			# Next word should be the filename
			if [[ $((i + 1)) -lt ${#COMP_WORDS[@]} ]]; then
				local next_word="${COMP_WORDS[$((i + 1))]}"
				# Only use it if it's not another option and the file exists
				if [[ "$next_word" != -* && -f "$next_word" ]]; then
					task_file="$next_word"
				fi
			fi
			break
			;;
		esac
	done

	# Check if previous word is --file or --info options,
	# if so, complete file names or task names
	case "$prev" in
	-f | --file)
		COMPREPLY=($(compgen -f -- "$cur"))
		return 0
		;;
	-i | --info)
		tasks=$(_run_get_tasks "$task_file")
		COMPREPLY=($(compgen -W "$tasks" -- "$cur"))
		return 0
		;;
	esac

	# If current word starts with -, complete the options
	if [[ "$cur" == -* ]]; then
		COMPREPLY=($(compgen -W "$OPTS" -- "$cur"))
		return 0
	fi

	# Check if already past the first non-option argument
	local non_option_count=0
	for ((i = 1; i < COMP_CWORD; i++)); do
		local word="${COMP_WORDS[$i]}"
		case "$word" in
		-f | --file | -i | --info)
			# Skip options and their arguments
			i=$((i + 1))
			;;
		-l | --list | --ls | -h | --help | --version)
			# These don't take separate arguments
			;;
		-*)
			# Unknown option, skip
			;;
		*)
			# This is a task name
			non_option_count=$((non_option_count + 1))
			;;
		esac
	done

	# If the task isn't found yet, complete task names from the appropriate file
	if [[ $non_option_count -eq 0 ]]; then
		tasks=$(_run_get_tasks "$task_file")
		COMPREPLY=($(compgen -W "$tasks" -- "$cur"))
		return 0
	fi

	# Don't provide any completions after a task name
	return 0
}

# Regex patterns for parsing the task file
TASK_NAME_PATTERN='[a-zA-Z]+[a-zA-Z0-9:_-]*'
TASK_DEF_PATTERN_1='^[[:blank:]]*run::('"${TASK_NAME_PATTERN}"')[[:blank:]]*\([[:blank:]]*\)'
TASK_DEF_PATTERN_2='^[[:blank:]]*function[[:blank:]]*run::('"${TASK_NAME_PATTERN}"')'

# _run_get_tasks is a helper function to extract task names from the task file
_run_get_tasks() {
	local task_file="$1"
	if [[ ! -f "$task_file" ]]; then
		return 0
	fi

	# Extract the task names from every line of a task file via regex
	local task_names=()
	while IFS= read -r line; do
		if [[ "$line" =~ $TASK_DEF_PATTERN_1 || "$line" =~ $TASK_DEF_PATTERN_2 ]]; then
			task_names+=("${BASH_REMATCH[1]}")
		fi
	done <"$task_file"

	printf '%s\n' "${task_names[@]}" | sort -u | tr '\n' ' '
}

# Register the completion function
complete -F _run_completion run
