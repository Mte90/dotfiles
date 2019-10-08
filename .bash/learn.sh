bold=$(tput bold)
normal=$(tput sgr0)
random_alias=$(alias | shuf -n 1 | sed -e "s/alias//" | tr "=" " ${normal}")

echo "Do you remember this alias?${bold}"
echo "  $random_alias"
