#!/usr/bin/env bash
# Find and warn about TODOs and FIXMEs.

SCRIPT=`basename ${BASH_SOURCE[0]}`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

function help {
  cat<< EOF
  This script finds all TODO and FIXME items in the docs. By default, it ignores those
  in "//" comments, but this can be turned off.
  The exit status is nonzero if one or more files were found to contain TODOs or FIXMEs.

  Usage: $SCRIPT [-h | --help] [-v | --verbose] [-s | --show-all] [file-or-directories]

  -h | --help            This message.
  -v | --verbose         Print more information about what's going on, such as the locations.
  -s | --show-all        Don't ignore TODO and FIXME comments (i.e., those in //). Default: they are ignored.
  file-or-directories    Search this list of files and directories, recursively. Default: src/main/asciidoc
EOF
}

function error {
  if [[ $1 = --help ]]
  then
    shift
    show_help=true
  fi
  echo "$0: ERROR: $@"
  echo ""
  [[ $show_help ]] && help
  exit 1
}

root_locations=()
show_all=false
verbose=false
while [ $# -ne 0 ]
do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    -s|--show*)
      show_all=true
      show_all_msg=", including comments,"
      ;;
    -v|--v*)
      verbose=true
      ;;
    -*)
      error --help "Unrecognized argument $1"
      ;;
    *)
      root_locations+=( $1 )
      ;;
  esac
  shift
done
[[ ${#root_locations[@]} -eq 0 ]] && root_locations=( src/main/asciidoc )

let found=0
for loc in ${root_locations[@]}
do
  [[ $verbose = true ]] && echo "==== Checking for TODOs and FIXMEs$show_all_msg in directory: $loc"
  file1=/tmp/tmp1-$$
  file2=/tmp/tmp2-$$
  file3=/tmp/tmp3-$$
  [[ -d "$loc" ]] || error "Location $loc does not exist!"
  find "$loc" -type f | while read f
  do
    nl -ba $f | while read line   # "nl" adds line numbers for nicer output.
    do
      echo "$f:$line"
    done
  done > $file1
  if [[ $show_all = true ]]
  then
    mv $file1 $file2            # keep everything
  else
    grep -Ev '^[^:]+: *[0-9]+\s*//' $file1 > $file2   # remove comments
  fi
  grep -iE -C0 '(TODO|FIXME)' $file2 >> $file3
  rm -f $file1 $file2
done

let found=0
[[ -s $file3 ]] && found=1 && cat <<EOF

**** ERROR:
**** ERROR: TODO and/or FIXME lines found in the directories: ${root_locations[@]}.
**** ERROR:

EOF
cat $file3
echo ""
rm $file3
exit $found
