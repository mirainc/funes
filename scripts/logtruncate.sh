set -e

for i in ./logs/*; do cat /dev/null > $i; done
