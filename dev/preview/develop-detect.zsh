# ------ initial repo ------ #

rm -rf ~/Project/node-demo ~/Project/golang-demo ~/Project/python-demo ~/Project/php-demo
mkdir -p ~/Project/node-demo ~/Project/golang-demo ~/Project/python-demo ~/Project/php-demo

# ------ prepare ------ #

touch ~/Project/node-demo/package.json
touch ~/Project/golang-demo/go.mod
touch ~/Project/python-demo/requirements.txt
touch ~/Project/php-demo/composer.json
cd ~/Project/python-demo
# default python is v2
python3 -m venv venv

# ------ ready ------ #
# terminal size: 72x16

clear
echo ''
cd ~/Project/node-demo
print -P "${PROMPT}"

echo '\n'
cd ~/Project/golang-demo
print -P "${PROMPT}"

echo '\n'
cd ~/Project/python-demo
print -P "${PROMPT}"

echo '\n'
. venv/bin/activate
print -P "${PROMPT}"
deactivate

echo ''
cd ~/Project/php-demo

