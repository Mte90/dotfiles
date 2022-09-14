random_alias=$(alias | shuf -n 1 | sed -e "s/alias//" | tr "=" " ${normal}")

echo "Do you remember this alias"
tput setaf 1
echo "  $random_alias"
tput sgr0
