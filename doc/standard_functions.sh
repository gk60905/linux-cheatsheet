#!/bin/bash

# Copied from https://github.com/gto76/standard-aliases, because I want this
# project to be classified as Bash porject.

#      _                  _               _ 
#  ___| |_ __ _ _ __   __| | __ _ _ __ __| |
# / __| __/ _` | '_ \ / _` |/ _` | '__/ _` |
# \__ \ || (_| | | | | (_| | (_| | | | (_| |
# |___/\__\__,_|_| |_|\__,_|\__,_|_|  \__,_|
#
#   __                  _   _
#  / _|_   _ _ __   ___| |_(_) ___  _ __  ___ 
# | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
# |  _| |_| | | | | (__| |_| | (_) | | | \__ \
# |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#

# All functions have long and descriptive names that start with
# two underscores (so they don't pollute the shells namespace).
# This functions are then "aliased" with shorter name (or
# names), that are specified in `~/.standardrc` configuration
# file. Be careful when changing long function names, because
# they might be used by other functions. Utility functions that
# are not meant to be aliased start with three underscores. Any
# new function that starts with two underscores will
# automatically be included in rc file when new shell is run.


########
# LESS #
########

# Runs less with:
#   * ignore case when searching, 
#   * do not ring a bell,
#   * do not mark empty lines with ~, 
#   * format prompt as "<page-number>/<all-pages> <filename>" and
#   * set tabs to 4 spaces.
__displayTextOrFileInPager() {
  less "${_LESS_OPTIONS[@]}" "$@"
}

# Prints with cat or displays with less contents of specified file, 
# depending on the length of file. If it runs less then it starts 
# diplaying text from the end if second argument is 'true'.
___printOrDisplayFileInPagerWithOrWithoutStartingAtEnd() {
  noOfLines=$(cat "$2" 2>/dev/null \
    | fold -w"$COLUMNS" \
    | wc -l)
  if [[ "$LINES" -gt "$noOfLines" ]]; then
    cat "$2"
  else
    if [[ "$1" == 'true' ]]; then
      __displayTextOrFileInPager +G "$2" 2>/dev/null
    else
      __displayTextOrFileInPager "$2" 2>/dev/null
    fi
  fi
}

# Prints with cat or displays with less piped text, depending on
# the length of input. If it runs less then it starts diplaying text
# from end if first argument is 'true'.
___printOrDisplayTextInPagerWithOrWithoutStartingAtEnd() {
  input=$(cat)
  noOfLines=$(echo "$input" | fold -w"$COLUMNS" | wc -l)
  if [[ "$LINES" -gt "$noOfLines" ]]; then
    echo "$input" #| cat 
    # Maybe cat is necessary in some cases because of
    # colors, I forgot if there is a reason for cat to
    # be here. 
  else
    if [[ "$1" == 'true' ]]; then
      echo "$input" | __displayTextOrFileInPager +G 2>/dev/null
    else
      echo "$input" | __displayTextOrFileInPager 2>/dev/null
    fi
  fi
}

# If any arguments are passed, then assumes the input is a file, whose
# name is specified by the argument. If there are no arguments, it then
# assumes the input is streamed in with a pipe.
___printOrDisplayTextOrFileInPagerWithOrWithoutStartingAtEnd() {
  if [[ "$#" -gt 1 ]]; then
    ___printOrDisplayFileInPagerWithOrWithoutStartingAtEnd "$@"
  else
    cat | ___printOrDisplayTextInPagerWithOrWithoutStartingAtEnd "$@"
  fi
}

# Runs cat or less, depending on number of lines in file or
# input.
__printOrDisplayTextOrFileInPager() {
  ___printOrDisplayTextOrFileInPagerWithOrWithoutStartingAtEnd 'false' "$@"
}

# Open cat or less +G (starts at the end of file), depending on
# no of lines of file or input.
___printOrDisplayTextOrFileInPagerStartingAtEnd() {
  ___printOrDisplayTextOrFileInPagerWithOrWithoutStartingAtEnd 'true' "$@"
}

# If file specified then runs cat or less, depending on no of
# lines of file. If input is piped, then it prints line by
# line. If all screen is filled, then it runs less.
___printTextOrFileUntilPageIsFilledThenDisplayInPager() {
  if [[ "$#" -gt 0 ]]; then
    ___printOrDisplayFileInPagerWithOrWithoutStartingAtEnd 'false' "$1"
  else
    noOfLines=0
    input=""
    while read -r line; do 
      input+=("$line")
      realLines=$(echo "$line" | fold -w"$COLUMNS" | wc -l)
      let noOfLines="$noOfLines"+"$realLines"
      if [ $noOfLines -gt $LINES ]; then 
        (for inputLine in "${input[@]}"; do
          echo "$inputLine" 
        done
        while read -r line; do 
          echo "$line"
        done) | less 2>/dev/null
        exit 
      fi   
      echo "$line"
    done 
  fi   
}


######
# LS #
######

# All other ls functions end up calling this one. It runs ls with:
#   * append indicator, 
#   * sort alphabetically by extension, 
#   * list by columns, 
#   * use color when stdout is connected to terminal and
#   * group directories before files.
___listDirectoryContents() {
  ls "${_LS_OPTIONS[@]}" "$@"
}

# Calls ___listDirectoryContents with: 
#   * set width to screen width or 69, whichever is smaller.
___listDirectoryContentsUsingShortListingFormat() {
  width=$(
    widthLimit=69
    if [[ "$COLUMNS" -lt "$widthLimit" ]]; then 
      echo "$COLUMNS"
    else 
      echo "$widthLimit"
    fi)
  ___listDirectoryContents --width="$width" "$@"
}

# Calls ___listDirectoryContents with: 
#   * use long listing format, 
#   * do not print groups,
#   * do not list owner, 
#   * print sizes in human readable format and
#   * print date as: '<month-by-word>, <day-of-month>, <year>,
#       <hour>:<minute>'.
___listDirectoryContentsUsingMediumListingFormat() {
   ___listDirectoryContents "${_LS_MEDIUM_OPTIONS[@]}" "$@"
}

# Calls ___listDirectoryContents with: 
#   * use long listing format.
___listDirectoryContentsUsingLongListingFormat() {
   ___listDirectoryContents -l "$@"
}

# $1 - function that lists dir contents
# ... - rest of parameters
___displayOutputOfListingFunctionInPagerIfItDoesentFitScreen() {
  listingFunction="$1"
  shift
  functionOutput=$("$listingFunction" --color=always "$@")
  if [[ $? -ne 0 ]]; then
    return
  fi
  noOfLines=$(
    echo "$functionOutput" \
      | fold -w"$COLUMNS" \
      |  wc -l)
  if [[ "$LINES" -gt "$noOfLines" ]]; then
    echo "$functionOutput"
  else
    echo "$functionOutput" | __displayTextOrFileInPager +G
  fi
}

__listOrDisplayDirectoryContentsInPagerUsingShortListingFormat() {
  ___displayOutputOfListingFunctionInPagerIfItDoesentFitScreen \
    ___listDirectoryContentsUsingShortListingFormat "$@"
}

__listOrDisplayDirectoryContentsInPagerUsingMediumListingFormat() {
  ___displayOutputOfListingFunctionInPagerIfItDoesentFitScreen \
    ___listDirectoryContentsUsingMediumListingFormat "$@"
}

__listOrDisplayDirectoryContentsInPagerUsingLongListingFormat() {
  ___displayOutputOfListingFunctionInPagerIfItDoesentFitScreen \
    ___listDirectoryContentsUsingLongListingFormat "$@"
}

__listOrDisplayAllDirectoryContentsInPagerUsingShortListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingShortListingFormat \
    --almost-all "$@"
}

__listOrDisplayAllDirectoryContentsInPagerUsingMediumListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingMediumListingFormat \
    --almost-all "$@"
}

__listOrDisplayAllDirectoryContentsInPagerUsingLongListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingLongListingFormat \
    --almost-all "$@"
}

__listOrDisplayDirectoryContentsInPagerOrderedByDateUsingShortListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingShortListingFormat \
    -t "$@"
}

__listOrDisplayDirectoryContentsInPagerOrderedByDateUsingMediumListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingMediumListingFormat \
    -t "$@"
}

__listOrDisplayDirectoryContentsInPagerOrderedByDateUsingLongListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingLongListingFormat \
    -t "$@"
}

__listOrDisplayMatchingDirectoriesInPagerUsingShortListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingShortListingFormat \
    --directory "$@"
}

__listOrDisplayMatchingDirectoriesInPagerUsingMediumListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingMediumListingFormat \
    --directory "$@"
}

__listOrDisplayMatchingDirectoriesInPagerUsingLongListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingLongListingFormat \
    --directory "$@"
}

__listOrDisplayInPagerOneDirectoryItemPerLineUsingShortListingFormat() {
  __listOrDisplayDirectoryContentsInPagerUsingShortListingFormat \
    -1 "$@"
}

__listOrDisplayInPagerOneDirectoryItemPerLineIncludingHiddenFilesUsingShortListingFormat() {
  __listOrDisplayAllDirectoryContentsInPagerUsingShortListingFormat \
    -1 "$@"
}

# Prints name of first file in the directory.
__listFirstFileInDirectory() {
  ls "$@" | head -1
}

# Prints name of a newest file in the directory.
__printNameOfNewestFileInDirectory() {
  ls -pt "$@" | grep -v / | head -1
}

# Prints name of a random file in the directory.
__printNameOfRandomFileInDirectory() {
  ls -pt | grep -v / | sort -R | head -1
}


# Prints all directories in current and sub-directories.
# TODO problem with find: no such file or directory in github.
__printAllSubdirectories() {
  find . -name .git -prune -o -type d | __printOrDisplayTextOrFileInPager
}

# Prints all file extensions of files in current and sub-directories.
__printAllFileExtensions() {
  find . -type f -name '*.*' | \
    sed 's|.*\.||' | \
    sort -u | \
    __printOrDisplayTextOrFileInPager
}


########
# TREE #
########

# Displays tree structure of current or specified folder, by
# running tree command with:
#   * always use colors,
#   * ignore .git directories and
#   * list directories before files.
__printDirectoryStructure() {
  tree "${_TREE_OPTIONS[@]}"  "$@" | __printOrDisplayTextOrFileInPager
}

__clearScreenAndprintDirectoryStructure() {
  clear
  __printDirectoryStructure "$@"
}


######
# CD #
######

# Goes up in the directory hierarchy the specified number of
# levels.
___goUpNumberOfDirectories() {
  if [[ "$#" -lt 1 ]]; then
    # Needs parameter.
    return 1
  fi
  re='^[1-9]$'
  if ! [[ "$1" =~ $re ]] ; then
    # Parameter is not a number or it's not the right size.
    return 2
  fi
  i=1
  while [[ "$i" -le "$1" ]]; do
    cd ..
    i=$(($i + 1))
  done
}

__goUpOneDirectory() {
  ___goUpNumberOfDirectories 1
}

__goUpTwoDirectories() {
  ___goUpNumberOfDirectories 2
}

__goUpThreeDirectories() {
  ___goUpNumberOfDirectories 3
}

__goUpFourDirectories() {
  ___goUpNumberOfDirectories 4
}

__goUpFiveDirectories() {
  ___goUpNumberOfDirectories 5
}

__goUpSixDirectories() {
  ___goUpNumberOfDirectories 6
}

# Mounts ISO file and cd-s into it.
__mountIsoAndCdInto() {
  sudo mkdir /media/"$1"
  sudo mount -o loop "$1" /media/"$1"
  cd /media/"$1"
}


#########
# FILES #
#########

# Runs cp in interactive mode (asks before it overwrites
# anything).
__copyFilesSafely() {
  cp --interactive --verbose "$@"
}

# Runs mv in interactive mode (asks before it overwrites
# anything).
__moveFilesSafely() {
  mv --interactive --verbose "$@"
}

# Runs rm in interactive mode (asks you for every file, if you
# really want to delete it). Run with -f option to override
# interactive mode.
__deleteFilesSafely() {
  rm --interactive "$@"
}

# Copies whole directory in interactive mode (asks before it
# overwrites anything).
__copyDirectoriesSafely() {
  cp --interactive --verbose --archive --recursive "$@"
}

# Moves whole directory in interactive mode (asks before it
# overwrites anything).
__moveDirectoriesSafely() {
  mv --interactive --verbose "$@"
}

# Removes whole directory in interactive mode (checks for every
# file if you really want to delete it). Run with -f option to
# override interactive mode.
__deleteDirectoriesSafely() {
  rm --interactive --recursive "$@"
}

# Makes directory (and its parent directories if necessary) and
# descends into.
__createDirectoryAndDescendInto() {
  mkdir --parents "$1"
  cd "$1"
}

# Backups file, by making a copy with '.bak' extension. All
# file's attributes are preserved.
__backupFile() {
  sudo cp --preserve "$1"{,.bak}
}

# Switches the contents of two specified files.
__switchContentsOfFiles() {
  tempFile=$(mktemp)
  sudo cp "$1" "$tempFile"
  sudo cp -f --no-preserve=mode,ownership "$2" "$1"
  sudo cp -f --no-preserve=mode,ownership "$tempFile" "$2"
}


#######
# PWD #
#######

# If no file specified, prints working directory, else full path
# of the file.
__printWorkingDirectoryOrPathToFile() {
  if [[ $# -eq 0 ]]; then
    echo "$PWD"
  else
    echo "$PWD"/"$@"
  fi      
}


########
# ECHO #
########

# Runs echo.
__printText() {
  echo "$@"
}

# Runs echo that interprets backslashed characters (\n,...).
__printTextInterpretingBackslashedCharacters() {
  echo -e "$@"
}

# Runs echo that doesn't print new line at the end.
__printTextWithoutTrailingNewline() {
  echo -n "$@"
}


#####################
# RUN IN BACKGROUND #
#####################

# Runs command in background. It doesn't hang up if shell
# is closed and it doesn't print output.
__runCommandInBackground() {
  nohup "$@" &>/dev/null &
}
complete -F _command __runCommandInBackground


##########
# BASICS #
##########

# Opens this file in Vim.
__editStandardAliases() {
  "$EDITOR" ~/.standard_aliases/functions
}

__editUsersStandardRc() {
  "$EDITOR" ~/.standardrc
}

__editProjectsStandardRc() {
  projectLocation=$(dirname $(readlink ~/.standard_aliases/functions))
  "$EDITOR" "$projectLocation"/standard_rc
}

# Runs bash. Run this command for changes to this file to take
# effect!
__startNewBashShell() {
  bash "$@"
}

# $1 - function name
# returns - whole function with options variable substituted with
#   real options, as defined at the end of standard_rc.
___getFunctionWithExpandedOptions() {
  calledFunction=$(type "$1")
  # Extract array names in form of "${_LESS_OPTIONS[@]}" from function.
  optionsArray=$(
    echo "$calledFunction" \
      | grep -o '_[A-Z_]*OPTIONS\[@\]' \
      | head -n1)
  expandedOptions=${!optionsArray}
  # Process options by adding backslashes in fornt of slashes, so they
  # dont break sed.
  expandedOptions=$(echo "$expandedOptions" | sed 's/\//\\\//g')
  optionsName=$(echo "$optionsArray" | grep -o '_[A-Z_]*OPTIONS')
  echo "$calledFunction" \
      | sed "s/...$optionsName\[@\]../$expandedOptions/g" \
      | grep --invert-match 'is a function' 
}

___printFirstFunctionThatAFunctionCallsAndExpandOptions() {
  nameOfCalledFunction=$(
    type "$@" \
      | grep -A1 '{' \
      | grep -o '__[^ ]*')
  ___getFunctionWithExpandedOptions "$nameOfCalledFunction"
}

# Prints location of specified command, or it's definition, if
# it is an alias. Run this command if you are not sure what an
# alias does!
__printCommandTypeOrDefinition() {
  # Checks if command is defined in standardrc, and if so it
  # runs type on the command it calls.
  standardAliases=$(
    grep ':' ~/.standardrc \
      | sed 's/:.*$//' \
      | tr -d ' ' \
      | sed 's/,/\n/g')
  if [[ $(echo "$standardAliases" | grep "^$1$") ]]; then
    ___printFirstFunctionThatAFunctionCallsAndExpandOptions "$1" \
      | __printOrDisplayTextOrFileInPager
  elif [[ $(echo "$1" | grep '^__') ]]; then
    # Also expand options if functin starts with '__' or '___'.
    # We'll assume it's a part of standard functions, although it's
    # not necessary true.
    ___getFunctionWithExpandedOptions "$1" \
      | __printOrDisplayTextOrFileInPager
  else
    type "$@" | __printOrDisplayTextOrFileInPager
  fi
}
complete -F _command __printCommandTypeOrDefinition

# Runs cat.
__printFileContents() {
  cat "$@"
}

# Prints the exit code of the last command.
__printExitCodeOfLastCommand() {
  echo $?
}

# Clears the screen.
__clearTheScreen() {
  clear
}

# Resets the screen.
__resetTheScreen() {
  reset "$@"
}

# Exits shell.
__exitBashShell() {
  exit
}

# Opens file with default application for it's file type, and
# runs in background.
__openFileWithDefaultApp() {
  __runCommandInBackground xdg-open "$@"
}

# Starts a new terminal, with same working directory. 
__openNewTerminalWithSameWorkingDirectory() {
  x-terminal-emulator "$@"
}

# Updates file's timestamp, or creates empty file, if it doesn't
# exits. 
# By default it doesn't use any options.
__updateFilesTimestampOrCreateNewOne() {
  touch "${_TOUCH_OPTIONS[@]}" "$@"
}

# Prints current date and time.
# By default it doesn't use any options.
__printDateAndTime() {
  date "${_DATE_OPTIONS[@]}" "$@"
}

# Runs make and sends both 'out' and 'error' streams to pager if
# necessary. 
# By default it doesn't use any options.
__runMakeWithPager() {
  make "${_MAKE_OPTIONS[@]}" "$@" 2>&1 \
    | __printLinesContainingPattern --color=always '^.*error|^.*warning|' \
    | __displayTextOrFileInPager
}
# Asigns make completion to command if available.
if [ -f /usr/share/bash-completion/completions/make ]; then
  . /usr/share/bash-completion/completions/make
  complete -F _make __runMakeWithPager
fi

# Start Nautilus file explorer in background.
__startFileExplorerInBackgroundInWorkingDirectory() {
  __runCommandInBackground nautilus .
}

# Runs diff with colors and sends output to pager if necessary.
# By default it doesn't use any options.
__compareFilesLineByLineInColor() {
  colordiff "${_DIFF_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}

# Creates executable bash script, or just changes modifiers to
# executable, if file already exists.
__makeFileExecutableOrCreateNewBashOrPythonScript() {
  if [[ ! -f "$1" ]]; then
    filename=$(basename "$1")
    extension="${filename##*.}"
    if [[ "$extension" == "py" ]]; then
      echo '#!/usr/bin/env python3' >> "$1"
      echo '#' >> "$1"
      echo "# Usage: $1 " >> "$1"
      echo '# ' >> "$1"
      echo >> "$1"
      echo 'import sys' >> "$1"
      echo 'import re' >> "$1"
      echo >> "$1"
      echo 'def main():' >> "$1"
      echo '    ' >> "$1"
      echo >> "$1"
      echo "if __name__ == '__main__':" >> "$1"
      echo '    main()' >> "$1"
    else
      echo '#!/bin/bash' >> "$1"
      echo '#' >> "$1"
      echo "# Usage: $1 " >> "$1"
      echo '# ' >> "$1"
      echo >> "$1"
      echo '# Stops execution if any command fails.' >> "$1"
      echo 'set -eo pipefail' >> "$1"
      echo >> "$1"
      echo 'main() {'>> "$1"
      echo '}'>> "$1"
      echo >> "$1"
      echo 'main "$@"'>> "$1"
    fi
  fi
  chmod u+x "$@"        
}


###########
# HISTORY #
###########

# Searches command history for pattern, or if none is specified,
# prints it whole.
__searchCommandHistoryForPattern() {
  if [ "$#" -eq 0 ]; then
    history \
      | head -n-1 \
      | ___printOrDisplayTextOrFileInPagerStartingAtEnd
  else
    history \
      | head -n-1 \
      | grep "$@" \
      | ___printOrDisplayTextOrFileInPagerStartingAtEnd
  fi
}


################
# TEXT EDITORS #
################

# Calls Vim with:
#   * open one tab per file.
__editFileWithVim() {
  vim "${_VIM_OPTIONS[@]}" "$@"
}

# Runs Vim in read only mode, with:
#   * open one tab per file.
__viewFileInVim() {
  view "${_VIM_OPTIONS[@]}" "$@"
}

# Runs Nano with this options:
#   * enable experimental undo (will most probably crash
#       if going deeper than first undo level!!!!!!!!!), 
#   * autoindent, 
#   * constantly show the cursor position, 
#   * log search and replace strings,
#   * enable edit of multiple files, 
#   * treat punctuation as part of words, 
#   * smooth scrolling and
#   * tab size set to 4 spaces.
__editFileWithNano() {
  nano "${_NANO_OPTIONS[@]}" "$@"
}

# Runs Nano in view only mode, with this options:
#   * enable experimental undo (will most probably crash
#       if going deeper than first undo level!!!!!!!!!), 
#   * autoindent, 
#   * constantly show the cursor position, 
#   * log search and replace strings,
#   * enable edit of multiple files, 
#   * treat punctuation as part of words, 
#   * smooth scrolling and
#   * tab size set to 4 spaces.
__viewFileInNano() {
  nano --view "${_NANO_OPTIONS[@]}" "$@"
}

# Runs Gedit in background.
# By default it doesn't use any options.
__editFileWithGedit() {
  __runCommandInBackground gedit "${_GEDIT_OPTIONS[@]}" "$@"
}

# Runs Sublime Text in background.
__editFileWithSublimeText() {
  __runCommandInBackground sublime_text "$@"
}


########
# SUDO #
########

# Runs command as sudo.
__executeCommandAsSuperUser() {
  sudo "$@"
}
complete -F _command __executeCommandAsSuperUser

# Executes last command as sudo.
__executeLastCommandAsSuperUser() {
  sudo $(history -p \!\!)
}

# Runs cp as superuser in interactive mode (asks before it
# overwrites anything).
__copyFilesSafelyAsSuperUser() {
  sudo cp --interactive --verbose "$@"
}

# Runs mv as superuser in interactive mode (asks before it
# overwrites anything).
__moveFilesSafelyAsSuperUser() {
  sudo mv --interactive --verbose "$@"
}

# Runs rm as superuser in interactive mode (asks you for every
# file, if you really want to delete it). Run with -f option to
# override interactive mode.
__deleteFilesSafelyAsSuperUser() {
  sudo rm --interactive "$@"
}

# Copies whole directory as superuser in interactive mode (asks
# before it overwrites anything).
__copyDirectoriesSafelyAsSuperUser() {
  sudo cp --interactive --verbose --archive --recursive "$@"
}

# Moves whole directory as superuser in interactive mode (asks
# before it overwrites anything).
__moveDirectoriesSafelyAsSuperUser() {
  sudo mv --interactive --verbose "$@"
}

# Removes whole directory as superuser in interactive mode
# (checks for every file if you really want to delete it). Run
# with -f option to override interactive mode.
__deleteDirectoriesSafelyAsSuperUser() {
  sudo rm --interactive --recursive "$@"
}

# Runs less as super user, with:
#   * ignore case when searching, 
#   * do not ring a bell,
#   * do not mark empty lines with ~, 
#   * format prompt as "<page-number>/<all-pages> <filename>" and
#   * set tabs to 4 spaces.
__displayTextOrFileInPagerAsSuperUser() {
  sudo less "${_LESS_OPTIONS[@]}" "$@"
}

# Runs Vim as super user, with:
#   * open one tab per file.
__editFileWithVimAsSuperUser() {
  sudoedit "$@"
}

# Runs Vim as super user in read only mode, with:
#   * open one tab per file.
__viewFileInVimAsSuperUser() {
  sudo view "${_VIM_OPTIONS[@]}" "$@"
}

# Runs Nano as super user with this options:
#   * enable experimental undo (will most probably crash
#       if going deeper than first undo level!!!!!!!!!), 
#   * autoindent, 
#   * constantly show the cursor position, 
#   * log search and replace strings,
#   * enable edit of multiple files, 
#   * treat punctuation as part of words, 
#   * smooth scrolling and
#   * tab size set to 4 spaces.
__editFileWithNanoAsSuperUser() {
  sudo nano "${_NANO_OPTIONS[@]}" "$@"
}
 
# Runs Gedit as super user. 
# By default it doesn't use any options.
__editFileWithGeditAsSuperUser() {
  sudo gedit "${_GEDIT_OPTIONS[@]}" "$@"
}

# Alias that puts 'sudo' in front of a command that needs super
# user privileges to run.

__runFdiskAsSuperUser() {
  sudo fdisk "$@"
}

__runUpdatedbAsSuperUser() {
  sudo updatedb "$@"
}

__runIfconfigAsSuperUser() {
  sudo ifconfig "$@"
}

__runTcpdumpAsSuperUser() {
  sudo tcpdump "$@"
}

__runRouteAsSuperUser() {
  sudo route "$@"
}

__runPm-hibernateAsSuperUser() {
  sudo pm-hibernate "$@"
}

__runPm-suspendAsSuperUser() {
  sudo pm-suspend "$@"
}

__runShutdownAsSuperUser() {
  sudo shutdown "$@"
}

__runFstrimAsSuperUser() {
  sudo fstrim "$@"
}

__runApt-getAsSuperUser() {
  sudo aptget "$@"
}

__runIwAsSuperUser() {
  sudo iw "$@"
}

__runNmapAsSuperUser() {
  sudo nmap "$@"
}

__runPartedAsSuperUser() {
  sudo parted "$@"
}

__runNtfsundeleteAsSuperUser() {
  sudo ntfsundelete "$@"
}

__runLshwAsSuperUser() {
  sudo lshw "$@"
}

__runChownAsSuperUser() {
  sudo chown "$@"
}

__runMountAsSuperUser() {
  sudo mount "$@"
}


#############
# PROCESESS #
#############

# Shows detailed overview of processes (task manager), by running htop.
# By default it doesn't use any options.
__runTerminalTaskManager() {
  htop "${_HTOP_OPTIONS[@]}" "$@"
}

# Prints user's processes and sends output to pager if
# necessary, by running ps. 
# By default it doesn't use any options.
__printUsersProcesses() {
  ps "${_PS_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}

# Prints every process on the system, by running ps with '-e' option.
# By default it doesn't use any other options.
__printAllProcesses() {
  ps -e "${_PS_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}

# Prints processes with specified pattern in their names,
# together with their PIDs, by running pgrep, with:
#   * list processes name.
__findProcessesWithPartOfName() {
  pgrep "${_PGREP_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}
# Asigns pgrep completion to command if available.
if [ -f /usr/share/bash-completion/completions/pgrep ]; then
   . /usr/share/bash-completion/completions/pgrep
   complete -F _pgrep __findProcessesWithPartOfName
fi

# Sends KILL signal to process with specified PID, instead of
# kill's default signal TERM.
__killProcessWithKillSignal() {
  kill -9 "$@"
}
complete -F _pids __killProcessWithKillSignal

# Traces system calls and signals, by running strace, with:
#   * print strings of maximum 2000 characters and 
#   * also trace child processes.
__traceSystemCalls() {
  strace "${_STRACE_OPTIONS[@]}" "$@" 2>&1 \
    | ___printTextOrFileUntilPageIsFilledThenDisplayInPager 
}
complete -F _command __traceSystemCalls


########
# TEXT #
########

# Runs head (prints first 10 lines of file or piped stream).
__printFirstTenLines() {
  head "$@"
}

# Prints first line of file or piped stream.
__printFirstLine() {
  head -n1 "$@"
}

# Runs tail (prints last 10 lines of file or piped stream).
__printLastTenLines() {
  tail "$@"
}

# Prints last line of file or piped stream.
__printLastLine() {
  tail -n1 "$@"
}

# Counts lines in file or piped stream.
__countLines() {
  wc -l "$@"
}

# Counts words in file or piped stream.
__countWords() {
  wc -w "$@"
}

# Deletes specified characters.
__deleteCharacters() {
  tr --delete "$@"
}

# Counts number of lines in files with specified extension 
# in current and sub-directories.
# $1 - file extension
__countLinesInFilesWithExtensionInWorkingAndSubdirectories() {
  rootDir="$PWD"
  no=0
  for file in *; do
    if [ -d "$file" ]; then
      cd "$file"
      recRes=$(
        __countLinesInFilesWithExtensionInWorkingAndSubdirectories "$1")
      let no=$no+"$recRes"
      cd "$rootDir"
    fi
    if [[ "$file" == *."$1" ]]; then
      let no=$no+$(cat "$file" | wc -l)
    fi
  done
  echo $no
}


##########
# TABLES #
##########

# Creates table out of input lines (lines up the columns). You
# need to specify the delimiter character.
__lineUpColumns() {
  column -t -s "$@"
}

# Treats input lines as rows of a table. With first argument you
# specify the delimiter character, and with secont, the columns
# you want to retain. For more columns use comma or dash (for
# ranges).
__keepColumns() {
  cut --delimiter="$1" --fields="$2" 
}

# Treats input lines as rows of a table and sorts them by column
# you specify with second parameter. First argument specifies
# the delimiter character. Using comma, more columns can be
# specified (in order of importance).
__sortLinesByColumn() { 
  sort --field-separator="$1" --key="$2"
}


##########
# SEARCH #
##########

# Runs grep with:
#   * highlighting matches, 
#   * not searching through .svn and .git folders,
#   * using Perl regex format (it has some additional operators, 
#       for instance, '+' meaning one or more times) and 
#   * ignoring case.
__printLinesContainingPattern() {
  grep --color=auto "${_GREP_OPTIONS[@]}" "$@"
}
complete -F _longopt __printLinesContainingPattern

# Runs __printLinesContainingPattern and sends output to pager.
__printOrDisplayWithPagerLinesContainingPattern() {
  __printLinesContainingPattern --color=always "$@" \
    | __printOrDisplayTextOrFileInPager
}

# Runs __printLinesContainingPattern with --recursive and 
# --line-number and sends output to pager.
__printOrDisplayWithPagerNumberedLinesContainingPatternInWorkingAndSubdirectories() {
  __printLinesContainingPattern \
    --recursive \
    --line-number \
    --color=always "$@" \
    | __printOrDisplayTextOrFileInPager
}

# Tries to find specified file using index. (Run 'sudo updatedb'
# to update the index). 
# By default it doesn't use any options.
__locateFilesOnFilesystemContainingPatternInTheirNames() {
  locate "${_LOCATE_OPTIONS[@]}" "$1" \
    | __printOrDisplayWithPagerLinesContainingPattern \
      $(echo "$1" | tr -d "\*")
}

# Searches for files containing pattern in their names in
# current and sub-directories.  Use filesystem regexes for
# search (aka *.*), and always surround them with quotation
# marks. Also highlights the matches.
# By default it doesn't use any options beside -name.
__locateFilesContainingPatternInTheirNamesInWorkingAndSubDirectories() {
  find . "${_FIND_OPTIONS[@]}" -name "$1" \
    | __printOrDisplayWithPagerLinesContainingPattern \
      $(echo "$1" | tr -d "\*") # | sed 's/^\.$//')
}


############
# ARCHIVES #
############

# Extracts archive of any type. (Author (Vitalii
# Tereshchuk)[https://github.com/xvoland])
__extractArchiveOfAnyType() {
  if [ -z "$1" ]; then
    # display usage if no parameters given
    echo -n "Usage: extract <path/file_name>"
    echo -n ".<zip|rar|bz2|gz|tar|tbz2|tgz|Z|"
    echo "7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
  else
    if [ -f "$1" ] ; then
      NAME=${1%.*}
      #mkdir $NAME && cd $NAME
      case "$1" in
        *.tar.bz2)   tar xvjf ./"$1"    ;;
        *.tar.gz)    tar xvzf ./"$1"    ;;
        *.tar.xz)    tar xvJf ./"$1"    ;;
        *.lzma)      unlzma ./"$1"      ;;
        *.bz2)       bunzip2 ./"$1"     ;;
        *.rar)       unrar x -ad ./"$1" ;;
        *.gz)        gunzip ./"$1"      ;;
        *.tar)       tar xvf ./"$1"     ;;
        *.tbz2)      tar xvjf ./"$1"    ;;
        *.tgz)       tar xvzf ./"$1"    ;;
        *.zip)       unzip ./"$1"       ;;
        *.Z)         uncompress ./"$1"  ;;
        *.7z)        7z x ./"$1"        ;;
        *.xz)        unxz ./"$1"        ;;
        *.exe)       cabextract ./"$1"  ;;
        *)           echo -n "extract: '$1'"
               echo "- unknown archive method" ;;
      esac
    else
      echo "'$1' - file does not exist"
    fi
  fi
}


########################
# TERMINAL MULTIPLEXER #
########################

# Runs Tmux.
# By default it doesn't use any options.
__runTerminalMultiplexer() {
  tmux "${_TMUX_OPTIONS[@]}" "$@"
}

# Runs Tmux, and attaches to last session.
__runTerminalMultiplexerAndAttachToLastSession() {
  tmux attach "$@"
}

# Lists all running Tmux sessions.
__listTerminalMultiplexersSessions() {
  tmux ls
}


######################
# SYSTEM INFORMATION #
######################

# Reports disk space of main partitions in human readable form.
__printAvailableDiskSpaceInSimplifiedForm() {
  df -h | grep "sd\|Size" | cat
}

# Displays disk space used by a folder or a file in human
# readable form.
__printDiskSpaceOccupiedByFileOrFolder() {
  du --summarize --human-readable "$@"
}

# Prints all and free memory in megabytes.
__printAllAndFreeMemorySpaceInMegabytes() {
  echo "all:  "$(free -m \
    | grep Mem \
    | sed 's/^Mem: *\([0-9]*\).*/\1/')" MB"
  echo "free: "$(free -m \
    | grep Mem \
    | sed 's/^[^ ]*[ ]*[^ ]*[ ]*[^ ]*[ ]*\([^ ]*\)[ ]*[^ ]*[ ]*[^ ]*[ ]*[^ ]*/\1/')" MB"
}

# Displays CPU's temperature.
__printTemperatureOfCpu() {
  acpi -t
}

# Prints battery status.
__printBatteryStatus() {
  acpi
}

# Prints kernel version and Linux distribution.
__printOperatingSystemInformation() {
  uname --all
}

# Prints verbose information about all PCI devices, by running
# lspci with:
#   * display detailed information about all devices.
__printInfoAboutPciDevices() {
  lspci "${_LSPCI_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}


#########
# POWER #
#########
 
# Restarts computer.
__restartComputer() {
  sudo reboot
}

# Shuts down computer.
__shutDownComputer() {
  sudo poweroff
}

# Hibernates.
__hibernateComputer() {
  sudo pm-hibernate
}

# Suspends.
__suspendComputer() {
  sudo pm-suspend
}


############
# KEYBOARD #
############

# Sets keyboard layout to us layout.
__switchToAmericanKeyboardLayout() {
  setxkbmap -layout us "$@"
}

# Gets keycode of pressed key.
__monitorKeycodesOfPressedKeys() {
  xev "$@"
}

# Turns key input repeat off.
__turnOffKeyRepeat() {
  xset -r
}

# Turns key input repeat on.
__turnOnKeyRepeat() {
  xset r
}


########
# MISC #
########

# Changes the hue of default blue color in Linux terminal (tty),
# that is otherwise hard to read.
__changeHueOfColorBlueInLinuxTerminal() {
  echo -en "\e]PC7373C9"
}

# Prints PATH variable, each entry in its own line.
__listDirectoriesContainedInPathVariable() {
  echo -e ${PATH//:/\\n}
}

# Runs console calculator with decimal numbers.
__runTerminalCalculatorThatSupportsDecimalNumbers() {
  gcalccmd "$@"
}

# Prints hexadecimal representation of file or piped stream.
# By default it doesn't use any options.
__printHexadecimalRepresentationOfFileOrStream() {
  hd "${_HD_OPTIONS[@]}" "$@" | __printOrDisplayTextOrFileInPager
}

# Runs profile script.
__runProfileScript() {
  source /etc/profile
}

# Sets bash to vi mode.
__changeBashLineEditingToViMode() {
  set -o vi
}

# Sets bash to emacs (normal) mode.
__changeBashLineEditingToEmacsMode() {
  set -o emacs
}

# Trims SSD disk.
__trimSsd() {
  sudo fstrim -v /
}

# Runs a typing tutor.
__startTypingTutor() {
  gtypist "$@"
}

# Prints description of a passed file extension.
__describeFileExtension() {
  curl --silent filext.com/file-extension/"$1" | \
    grep 'The .* file type is primarily associated' | \
    sed 's/^\t*//' \
    | sed 's/ *<.div>$//'
}


######################
# PACKAGE MANAGEMENT #
######################

# Installs package.
__installPackage() {
  if [[ "$__standardAliasesDetectedOS" == "mac" ]]; then
    brew install "$@"
  else
    sudo apt-get install "$@"
  fi
}

# Updates package information.
__updateInformationAboutAvailablePackages() {
  sudo apt-get update
}

# Upgrades all packages to newest available version.
__upgradeAllPackages() {
  sudo apt-get upgrade
}

# Tries to upgrade all packages. If any dependency conflicts
# arise, then it handles them intelligently, by upgrading the
# most important packages at the expense of less important ones.
__upgradeAllPackagesIntelligently() {
  sudo apt-get dist-upgrade
}

# Removes package and all the packages this package dependent on
# and were only used by this package.
__removePackageAndAllUnneededPackages() {
  sudo apt-get remove "$@" && __removeUnneededPackages
}

# Removes package, together with its configuration files. All
# the packages this package dependent on and were only used by
# this package are also removed.
__removePackageAndAllUnneededPackagesTogetherWithConfigurationFiles() {
  sudo apt-get purge "$@" && __removeUnneededPackages
}

# Removes packages that were automatically installed to satisfy
# dependencies for other packages and are now no longer needed.
__removeUnneededPackages() {
  sudo apt-get autoremove
}

# Prints packages that were installed by the user, in order of
# installation.
__printPackagesThatWereInstalledByUser() {
  cat /var/log/apt/history.log \
    | grep "apt-get install" \
    | sed "s/.* //" \
    | ___printOrDisplayTextOrFileInPagerStartingAtEnd
}

# Prints all installed packages.
__printAllInstalledPackages() {
  dpkg --get-selections \
    | grep -v deinstall \
    | __printOrDisplayTextOrFileInPager
}

# Shows on which packages specified package depends.
__printPackageDependencies() { 
  apt-cache show "$@" \
    | grep Depends \
    | sed 's/Depends:/ /' \
    | sed 's/,/\n /g' \
    | __printOrDisplayTextOrFileInPager
}


#######################
# PACKAGE INFORMATION #
#######################

# Prints package description.
__printPackageDescription() {
  apt-cache show "$@" | grep "^ " | __printOrDisplayTextOrFileInPager
}

# Returns 0 if package is instaled, or non-zero if not.
___isPackageInstalled() {
  dpkg -s "$@" &> /dev/null
  return "$?"
}

# Prints installed and remote version of package.
___printPackagesInstalledAndAvailableVersion() {
  versionInfo=$(apt-cache policy "$@")
  echo "$versionInfo" | grep Installed | sed 's/^ *//'
  echo "$versionInfo" | grep Candidate | sed 's/^ *//'
}

# Prints installed and remote version of package or command
# (that is part of package). Command version only works for
# installed commands.
__printInstalledAndAvailableVersionOfPackageOrCommand() {
  # Check if passed name is a package, and print its version
  # if it is.
  packageVersion=$(___printPackagesInstalledAndAvailableVersion "$@")
  if [[ "$packageVersion" != "" ]]; then 
    echo "$packageVersion"
  else
    # Check if passed name is an installed command, and
    # print its package version if it is.
    packageInfo=$(
      ___printInstalledPackageThatProvidesCommandAndItsLocation "$@")
    packageName=$(echo "$packageInfo" | sed 's/:.*$//')
    if [[ "$packageName" != "" ]]; then 
      echo "Package:   $packageName"
      ___printPackagesInstalledAndAvailableVersion "$packageName"
    fi
  fi
}

# Find which installed package provides specified command.
___printInstalledPackageThatProvidesCommandAndItsLocation() {
  file=$(sudo which "$1")
  if [ "$file" == "" ]; then 
    return
  fi  
  resolved=$(readlink -f "$file")
  dpkg -S "$resolved" \
    | __printLinesContainingPattern "^.*:"
}

# Converts man section number into a description.
___getManSectionNameFromNumber() {
  case "$1" in
    1)      echo "user command"                     ;;
    2)      echo "system call"                      ;;
    3)      echo "c function"                       ;;
    4)      echo "device file"                      ;;
    5)      echo "file format or convention"        ;;
    6)      echo "game"                             ;; 
    7)      echo "miscallaneous"                    ;;
    8)      echo "su command"                       ;;
    9)      echo "kernel routine"                   ;;
  esac
}

# If command is available then it prints it's description,
# package and location.
__printPackageOfInstalledCommandTogetherWithDescriptionAndLocation() {
  call1=$(sudo whatis "$@" 2> /dev/null)
  if [ "$?" == "0" ]; then 
    while IFS= read -r line; do
      commandType=$(
        ___getManSectionNameFromNumber $(
          echo "$line" | sed 's/.*(\([1-9]\)).*/\1/'))
      echo "$line" "($commandType)"
    done <<< "$call1"
    echo -n "Package:   "
    packageInfo=$(
      ___printInstalledPackageThatProvidesCommandAndItsLocation "$@")
    echo "$packageInfo" | sed 's/: /\nLocation:  /'
    return 0
  fi
  return 1
}


##################
# PACKAGE SEARCH #
##################

# Searches packages, that can be installed with apt-get. Search
# is performed on their names and short descriptions.
__findAvailablePackagesWithPartOfNameOrDescription() {
  apt-cache search "$@" \
    | __printOrDisplayWithPagerLinesContainingPattern  "$@"
}

# Runs apropos, a command that finds installed commands, with
# provided pattern in their names or descriptions. Matches get
# highlighted.
__findInstalledCommandsWithPartOfNameOrDescription() {
  apropos "$@" \
    | __printOrDisplayWithPagerLinesContainingPattern  "$@"
}

# Finds which available packages provide specified command.
__findAvailablePackagesThatProvideCommand() {
  apt-file -x search '^.*bin/'$1'$' \
    | __printOrDisplayWithPagerLinesContainingPattern "^.*:"
}

# Searches packages, that can be installed with apt-get. Search
# is performed only on their names.
___findAvailablePackagesWithPartOfName() {
  apt-cache search "$1" \
    | __printLinesContainingPattern "^[^ ]*$1[^ ]*" \
    | __printOrDisplayWithPagerLinesContainingPattern "$1" 
}

# Finds which available packages contain specified file or have
# the pattern in their names.
___findAvailablePackagesWithPartOfNameOrFullCommand() {
  (echo   "PACKAGES PROVIDING COMMAND NAMED \"$1\""
  echo -n "==================================="
  echo "$1" | sed 's/./=/g'
  __findAvailablePackagesThatProvideCommand "$@"
  echo -e "\nPACKAGES CONTAINING \"$@\" IN THEIR NAMES"   
  echo -n   "====================================="
  echo "$1" | sed 's/./=/g'
  ___findAvailablePackagesWithPartOfName "$@") \
    | ___printTextOrFileUntilPageIsFilledThenDisplayInPager 
}

___printDescriptionOfBashBuiltinOrAnAlias() {
  #answer=$(type "$@")
  answer=$(__printCommandTypeOrDefinition "$@")
  echo "$answer"
  if [[ $(echo "$answer" | grep "is a shell") != "" ]]; then
    help "$@"
  fi
}

# Universal command description search function. First tries
# whatis, then apt-cache show, then type and finally apt-file.
# When one of them succeeds in finding the description the
# function returns.  describe package or command or find
# available packages with part of name or available packages
# that provide command
__describePackageOrCommandOrFindAvailablePackagesWithPartOfNameOrCommand() {
  # Checks if it is an installed command.
  __printPackageOfInstalledCommandTogetherWithDescriptionAndLocation "$@"
  if [ "$?" == "0" ]; then 
    return
  fi

  # Checks if it is a package.
  call2=$(__printPackageDescription "$@" 2> /dev/null) 
  if [ "$call2" != "" ]; then
    echo "$call2" | __printOrDisplayTextOrFileInPager
    return
  fi

  # Checks if it is an alias of bash builtin.
  call3=$(___printDescriptionOfBashBuiltinOrAnAlias "$@" 2> /dev/null)
  if [ "$call3" != "" ]; then
    echo "$call3" | __printOrDisplayTextOrFileInPager
    return
  fi

  # Search all available commands and packages with part of
  # the name.
  ___findAvailablePackagesWithPartOfNameOrFullCommand "$@" 
}


#######
# GIT #
#######

# Commits changed and deleted files. Commit message must be
# entered as parameter.
__commitChangedAndDeletedFilesWithMessage() {
  git commit -am "$@"
}

# Commits changed and deleted files. Opens text editor, so
# proper commit message can be entered.
__commitChangedAndDeletedFilesAndEditMessageInEditor() {
  git commit -a "$@"
}

# Creates an empty Git repository or reinitializes an existing
# one (nondestructive).
__initializeRepository() {
  git init "$@"
}

# Pushes changes to remote repository.
__pushChangesToRemoteRepository() {
  git push "$@"
}

# Pulls changes from remote repository.
__pullChangesFromRemoteRepository() {
  git pull "$@"
}

# Joins specified branch with current one.
__mergeSpecifiedBranchWithCurrentOne() {
  git merge "$@"
}

# Switches to another branch, or checks-out a file from
# repository.
__checkoutBranchOrFile() {
  git checkout "$@"
}

# Prints all branches, or creates new one, if name is specified. 
__listBranchesOrCreateNewOne() {
  git branch "$@"
}

# Prints short status of repository.
__printShortRepositoryStatus() {
  git -c color.status=always status -sb "$@" \
    | __printOrDisplayTextOrFileInPager
}

# Prints graph of commits, with only first
# line of commit messages and shortened hashes.
__displayMinimalLogOfCommits() {
  git log --graph --abbrev-commit --decorate --format=format:'%C(yellow)%h%C(reset)%C(auto)%d%C(reset) %C(white)%s%C(reset)' --all
}

# Prints nicely decorated graph of commits, with only first
# line of commit messages, shortened hashes and full dates.
__displayMediumLogOfCommits() {
  git log --graph --abbrev-commit --decorate --format=format:'%C(yellow)%h%C(reset) - %C(cyan)%aD%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n'' %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all
}

# Prints nicely decorated graph of commits, with commit
# messages, full hashes and full dates. 
__displayLogOfCommits() {
  git log --decorate --graph --all "$@"
}

# Updates information about state of the remote repository and
# prints status.
__updateInformationAboutRemoteRepositoryAndPrintStatus() {
  git remote update "$@"
  __printShortRepositoryStatus
}

# Shows changes between commits. If no parameter is given, then
# shows changes between last commit and current state.
__displayChangesBetweenCommits() {
  git diff "$@"
}

# Adds file to repository.
__addFilesToRepository() {
  git add "$@"
}

# Moves file or directory. Git will in most cases recognize that
# files were moved even if regular 'mv' command was used, but
# this way it is for shure.
__moveRepositoriesFiles() {
  git mv "$@"
}

# Prints files that are in repository.
__listFilesThatAreInRepository() {
  git ls-files "$@"
}


##########
# GITHUB #
##########

# Clones project from Github. User and project names must be
# specified as <user>/<project>.
__cloneGithubProject() {
  git clone git@github.com:/"$1".git
}

# Sets remote repository to specified Github project. Repository
# must be entered as <user>/<project>.
__setGithubProjectAsRemoteRepository() {
  git remote add origin git@github.com:/"$1".git
  git pull origin master
  git push --set-upstream origin master
}

# Clones all users Github projects in working directory.
__cloneAllUsersGithubProjects() {
  if [[ -z "$1" ]]; then
    exit
  fi
  tempFile=$(mktemp)
  wget 'https://github.com/gto76?tab=repositories' -O "$tempFile"
  repos=$(grep "$1"/[^//\"]* -o "$tempFile" \
    | sort -u \
    | grep -v follow)
  while read -r line; do
    git clone git@github.com:"$line"
  done <<< "$repos"
}


###########
# NETWORK #
###########

# Prints internal ip.
__printInternalIp() {
  /sbin/ifconfig \
    | grep "inet addr:" \
    | grep -v "inet addr:127" \
    | grep -o addr:[0-9.]* \
    | grep -o [0-9.]\* \
    | cat
}

# Prints external ip. 
__printExternalIp() {
  lynx --dump http://ipecho.net/plain | grep -o [0-9.]\*
}

# Prints gateways ip.
__printGatewaysIp() {
  route -n \
    | tail -n+3 \
    | grep G \
    | sed 's/^[0-9.]* *\([0-9.]*\).*$/\1/'
}

# Prints mac addresses of local devices.
__printMacAddressesOfNetworkDevices() {
  ifconfig | grep HWaddr | cat
}

# Pings gateway, ip address of noip.com and www.google.com.
__pingGatewayAndGoogle() {
  ping -c 1 -q $(gateway) | grep --color=never -A 1 statistics
  ping -c 1 -q 8.23.224.107 | grep --color=never -A 1 statistics
  ping -c 1 -q www.google.com | grep --color=never -A 1 statistics
}

# Scans addresses of local network. If a number is specified it
# scans local addresses up to this number (0-255).
__scanLocalNetwork() {
  if [[ $# -eq 0 ]]; then
    third=$(ip1 \
      | sed -e :a -e 's/[0-9]*.\([0-9]\).[0-9]*.[0.9]*/\1/;ta')
    forth="254"
  fi
  if [[ $# -eq 1 ]]; then
    third=$(ip1 \
      | sed -e :a -e 's/[0-9]*.\([0-9]\).[0-9]*.[0.9]*/\1/;ta')
    forth="$1"
  fi
  if [[ $# -gt 1 ]]; then
    third="$1"
    forth="$2"
  fi
  nmap -sP 192.168."$third".0-"$forth"
}

# Prints 'OK' if specified address or ip can be reached with
# ping, or 'Fail' if not.
___isAddressReachable() {
  pingResult=$(
    ping -c 1 -q "$1" \
      | grep --color=never -A 1 statistics \
      | grep "1 received")
  if [ "$pingResult" != "" ]; then
    echo -n "OK"
  else
    echo -n "Fail"
  fi
}

# Prints status of the ssh port of the specified host.
___printStatusOfSshPortAtAddress() {
  nmap $(echo "$1" | tr -d ' ') -p22 \
    | grep '22/tcp' \
    | sed 's/^[^ ]* \([^ ]*\) .*$/\1/'
}

# Scans first 20 addresses of local network and prints yours,
# gateways and the ip-s of other connected devices. Also checks
# their ssh port status.  After that checks checks if connection
# to the internet is available by pinging Google and ip address
# of noip.com.
__printSshPortStatusOfLocalDevicesAndPingGoogle() {
  localIp=$(ip1)
  gateway=$(gateway)
  echo -n "You:      $localIp    ssh: "
  ___printStatusOfSshPortAtAddress $(ip2)
  echo -n "Gateway:  $gateway    ssh: "
  ___printStatusOfSshPortAtAddress "$gateway"
  all=$(nmap1 20)
  allFiltered=$(
    echo "$all" | 
    grep -v "$localIp" |
    grep -v "$gateway" |
    grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" |
    sed 's/^/          /g' ) 
  len=${#allFiltered} 
  allFiltered=${allFiltered:6:len-6} 
  if [[ "$allFiltered" != "" ]]; then
    echo -n "Other:"
    while IFS= read -r line; do 
      echo -n "$line    ssh: "
      ___printStatusOfSshPortAtAddress "$line"    
    done <<< "$allFiltered"
  fi
  testIp="8.23.224.107"
  echo -n "Internet: $testIp   Ping: "
  ___isAddressReachable "$testIp"
  echo
  testDomain="www.google.com"
  echo -n "          $testDomain Ping: "
  ___isAddressReachable "$testDomain"
  echo
}


############
# WIRELESS #
############

# Disables wireless device.
__blockWirelessDevice() {
  sudo rfkill block $(
    sudo rfkill list \
      | grep Wireless \
      | grep ^[0-9] -o)
}

# Enables wireless device.
__unblockWirelessDevice() {
  sudo rfkill unblock $(
    sudo rfkill list \
      | grep Wireless \
      | grep ^[0-9] -o)
}

# Resets wireless device.
__resetWirelessDevice() {
  woff
  won
}

# Activates wireless interface (driver).
__activateWirelessInterface() {
  sudo ifconfig wlan0 up
}

# Shuts down wireless interface (driver).
__deactivateWirelessInterface() {
  sudo ifconfig wlan0 down
}

# Displays wireless networks in range.
__printWirelessNetworksInRange() {
  sudo iwlist wlan0 scan \
    | grep Quality -A2 \
    | tr -d "\n" \
    | sed 's/--/\n/g' \
    | sed -e 's/ \+/ /g' \
    | sort -r \
    | sed 's/ Quality=//g' \
    | sed 's/\/70 Signal level=-[0-9]* dBm Encryption key:/ /g' \
    | sed 's/ ESSID:/ /g'
}


############
# INTERNET #
############

# Runs default browser in background.
__startDefaultBrowserInBackground() {
  __runCommandInBackground sensible-browser "$@"
}

# Runs Firefox in background.
__startFirefoxInBackground() {
  __runCommandInBackground firefox "$@"
}

# Runs Chrome in background with:
#   * --touch-devices=123, a setting that resolves some
#       bug in some cases (it is probably already fixed).
__startChromeInBackground() {
  __runCommandInBackground google-chrome "${_CHROME_OPTIONS[@]}" "$@"
}

# Runs Lynx with:
#   * accept all cookies,
#   * start in Google and 
#   * using Vim mode for navigation.
__startTerminalWebBrowser() {
  lynx "${_LYNX_OPTIONS[@]}" "$@"
}


#########
# AUDIO #
#########

# Control volume of all audio channels.
__startTerminalVolumeControl() {
  alsamixer "$@"
}

# Set master volume in rage of 0 to 100.
___setVolumeTo() {
  amixer set Master playback "$1"
}

# Increases volume by 6dB.
__increaseVolumeBySixDecibels() {
  ___setVolumeTo "6%+" | tail -n 1
}

# Decreases volume by 6dB.
__decreaseVolumeBySixDecibels() {
  ___setVolumeTo "6%-" | tail -n 1
}

# Increases volume by 2dB.
__increaseVolumeByTwoDecibels() {
  ___setVolumeTo "2%+" | tail -n 1
}

# Decreases volume by 2dB.
__decreaseVolumeByTwoDecibels() {
  ___setVolumeTo "2%-" | tail -n 1
}


#############
# FRAMEWORK #
#############

# Opens this file in default editor.
__editStandardFunctions() {
  "${EDITOR:-nano}" ~/.standard_aliases/functions
}

# Opens users configuration file in default editor.
__editStandardRc() {
  "${EDITOR:-nano}" ~/.standardrc
}
