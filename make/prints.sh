#!/usr/bin/env bash
#
# Helper script with colorful print functions

# Color values sorted as
#   - bold (<NAME>_B)
#   - marker-background (<NAME>_M)
#   - underline (<NAME>_U)
#   - normal (<NAME>)
#
# END is the terminator to skip back to default color

END="\033[0m"

{
  BLACK_B="\033[1;30m"
  BLACK_M="\033[40m"
  BLACK_U="\033[4;30m"
  BLACK="\033[0;30m"

  BLUE_B="\033[1;34m"
  BLUE_M="\033[44m"
  BLUE_U="\033[4;34m"
  BLUE="\033[0;34m"

  GRAY_B="\033[1;90m"
  GRAY_M="\033[100m"
  GRAY_U="\033[4;90m"
  GRAY="\033[0;90m"

  GREEN_B="\033[1;32m"
  GREEN_M="\033[42m"
  GREEN_U="\033[4;32m"
  GREEN="\033[0;32m"

  LIGHTBLUE_B="\033[1;36m"
  LIGHTBLUE_M="\033[46m"
  LIGHTBLUE_U="\033[4;36m"
  LIGHTBLUE="\033[0;36m"

  LIGHTGRAY_B="\033[1;97m"
  LIGHTGRAY_M="\033[107m"
  LIGHTGRAY_U="\033[4;97m"
  LIGHTGRAY="\033[0;97m"

  LIGHTGREEN_B="\033[1;92m"
  LIGHTGREEN_M="\033[102m"
  LIGHTGREEN_U="\033[4;92m"
  LIGHTGREEN="\033[0;92m"

  LIGHTPURPLE_B="\033[1;94m"
  LIGHTPURPLE_M="\033[104m"
  LIGHTPURPLE_U="\033[4;94m"
  LIGHTPURPLE="\033[0;94m"

  LIGHTRED_B="\033[1;91m"
  LIGHTRED_M="\033[101m"
  LIGHTRED_U="\033[4;91m"
  LIGHTRED="\033[0;91m"

  LIGHTYELLOW_B="\033[1;93m"
  LIGHTYELLOW_M="\033[103m"
  LIGHTYELLOW_U="\033[4;93m"
  LIGHTYELLOW="\033[0;93m"

  PURPLE_B="\033[1;35m"
  PURPLE_M="\033[45m"
  PURPLE_U="\033[4;35m"
  PURPLE="\033[0;35m"

  RED_B="\033[1;31m"
  RED_M="\033[41m"
  RED_U="\033[4;31m"
  RED="\033[0;31m"

  WHITE_B="\033[1;37m"
  WHITE_M="\033[47m"
  WHITE_U="\033[4;37m"
  WHITE="\033[0;37m"

  YELLOW_B="\033[1;33m"
  YELLOW_M="\033[43m"
  YELLOW_U="\033[4;33m"
  YELLOW="\033[0;33m"
}

function print_info {
  echo -e "${GREEN_B}${1}${END}"
}

function print_warning {
  echo -e "${YELLOW_B}${1}${END}"
}

function print_error {
  echo -e "${RED_B}${1}${END}"
}

function print_command {
  echo -e "${LIGHTBLUE_B}${1}${END}"
}

function print_stage {
  echo -e "${BLUE_B}${1}${END}"
}