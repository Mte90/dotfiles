#!/usr/bin/env bash
# https://github.com/dense-analysis/ale/issues/2427#issuecomment-499273528
# https://stackoverflow.com/questions/31224368/how-do-i-escape-a-series-of-backslashes-in-a-bash-printf
# printf avoids legit backslashes turning into escape chars :/
out=$(printf "%s" "$(phpcbf -q $@)")
# # if there are no errors, don't show me any text! Used by vim-ale. If this
# # isn't used, when the "No fixable errors found" output shows up, vim will
# # replace the contents of the file with that output!
if [[ "$( echo \"$out\" | grep 'No fixable' )" ]]; then
    exit
fi
if [[ "$( echo \"$out\" | grep 'Warning: ' )" ]]; then
    exit
fi
# printf avoids legit backslashes turning into escape chars :/
printf "%s" "$out"
