# ------ initial repo ------ #
rm -rf ~/Project/python-demo
mkdir -p ~/Project/python-demo

cd ~/Project/python-demo

git init

# ------ initial repo ------ #

touch requirements.txt
echo venv > .gitignore
git add --all
git commit -m "init"
python3 -m venv venv


# ------ ready ------ #
# terminal size: 98x12

cd ~/Project/python-demo
git checkout .
. venv/bin/activate

clear
echo '\n'
print -P "${PROMPT}"

deactivate

@jov.pin-execute-info 6 1

echo ''
echo changes >> requirements.txt
