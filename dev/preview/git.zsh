# ------ initial repo ------ #

rm -rf ~/Project/git-demo
mkdir -p ~/Project

git clone git@github.com:zthxxx/jovial.git ~/Project/git-demo

cd ~/Project/git-demo
git remote remove origin

# ------ prepare ------ #

gDcb develop
gco master
clear

# ------ ready ------ #
# terminal size: 73x15

git checkout develop

echo Change something >> README.md

git checkout .


# ------ prepare ------ #
# terminal size: 89x23

gco master
git reset ea7f3f5 --hard

echo Hello World > README.md
git add --all
git commit -m 'test: hello world for preview'

echo Change 1 >> README.md
git add --all
git commit -m 'test: hello world for preview'

echo Change 2 >> README.md
git add --all
git commit -m 'test: hello world for preview'

clear

# ------ ready ------ #

git merge 97c1458 &> /dev/null

git merge --abort


git rebase 97c1458 &> /dev/null

git rebase --abort


git cherry-pick 97c1458 &> /dev/null

git cherry-pick --abort
