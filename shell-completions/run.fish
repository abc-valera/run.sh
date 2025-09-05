#!/usr/bin/env fish

# fish completion for the run task runner
# Learn more: https://run.jotaen.net

# Installation:
#	put this file in the completions subdir of your fish configuration directory,
#	usually ~/.config/fish/completions, to have it loaded automatically.

# Helper function to extract task names from a task file
function __run_get_tasks
    set -l task_file $argv[1]

    # Regex patterns for parsing the task file
    set -l TASK_NAME_PATTERN '[a-zA-Z]+[a-zA-Z0-9:_-]*'
    set -l TASK_DEF_PATTERN_1 '^[[:blank:]]*run::('$TASK_NAME_PATTERN')[[:blank:]]*\([[:blank:]]*\)'
    set -l TASK_DEF_PATTERN_2 '^[[:blank:]]*function[[:blank:]]*run::('$TASK_NAME_PATTERN')'

    if not test -f "$task_file"
        return
    end
    
    set -l task_names
    
    while read -l line
        # Match both task definition patterns
        if string match -qr $TASK_DEF_PATTERN_1 -- "$line"
            set -l task (string replace -r $TASK_DEF_PATTERN_1 '$1' -- "$line")
            set task (string sub -e -1 $task)
			set task (string trim -- $task)
            set -a task_names $task
        else if string match -qr $TASK_DEF_PATTERN_2 -- "$line"
            set -l task (string replace -r $TASK_DEF_PATTERN_2 '$1' -- "$line")
			set task (string sub -e -1 $task)
			set task (string trim -- $task)
            set -a task_names $task
        end
    end < "$task_file"

    # Remove duplicates and print each on a new line
    printf '%s\n' $task_names | sort -u
end

# Helper function to get the task file from command line arguments
function __run_get_task_file
    set -l task_file "./run.sh"  # default
    set -l tokens (commandline -opc)
    
    # Look for -f/--file option in the command line
    set -l i 1
    while test $i -le (count $tokens)
        set -l current $tokens[$i]
        
        switch $current
            case '-f' '--file'
                # Next token should be the filename
                set -l next_i (math $i + 1)
                if test $next_i -le (count $tokens)
                    set -l next_token $tokens[$next_i]
                    # Only use it if it's not another option and the file exists
                    if not string match -q -- '-*' "$next_token"; and test -f "$next_token"
                        set task_file "$next_token"
                        break
                    end
                end
            case '--file=*'
                set -l filename (string sub -s 8 -- "$current")
                if test -f "$filename"
                    set task_file "$filename"
                    break
                end
            case '-f=*'
                set -l filename (string sub -s 4 -- "$current")
                if test -f "$filename"
                    set task_file "$filename"
                    break
                end
        end
        set i (math $i + 1)
    end
    
    echo $task_file
end

# Helper function to check if we already have a task name
function __run_no_task_yet
    set -l tokens (commandline -opc)
    set -l task_file (__run_get_task_file)
    set -l available_tasks (__run_get_tasks "$task_file")
    
    # Skip the command name and look for non-option arguments
    set -l i 2
    while test $i -le (count $tokens)
        set -l current $tokens[$i]
        
        switch $current
            case '-f' '--file' '-i' '--info'
                # Skip option and its argument
                set i (math $i + 2)
                continue
            case '-l' '--list' '--ls' '-h' '--help' '--version'
                # Skip standalone options
                set i (math $i + 1)
                continue
            case '--file=*' '--info=*' '-f=*' '-i=*'
                # Skip options with embedded arguments
                set i (math $i + 1)
                continue
            case '-*'
                # Skip unknown options
                set i (math $i + 1)
                continue
            case '*'
                # This might be a task name - check if it's in our list
                if contains "$current" $available_tasks
                    return 1  # We found a task, don't complete more tasks
                end
        end
        set i (math $i + 1)
    end
    
    return 0  # No task found yet, can complete task names
end

# Complete options
complete -c run -s f -l file -d "Specify the task file" -r -F
complete -c run -s i -l info -d "Show task description" -x -a "(__run_get_tasks (__run_get_task_file))"
complete -c run -s l -l list -d "List all available tasks"
complete -c run -l ls -d "List all available tasks"
complete -c run -s h -l help -d "Print help"
complete -c run -l version -d "Print version"

# Complete task names when no task has been specified yet
complete -c run -n "__run_no_task_yet" -x -a "(__run_get_tasks (__run_get_task_file))"