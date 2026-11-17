#!/bin/sh
set -eu

# Package installation runs only in the build VM; the published VM has no network device.
printf '%s\n' \
  'https://dl-cdn.alpinelinux.org/alpine/v3.24/main' \
  'https://dl-cdn.alpinelinux.org/alpine/v3.24/community' > /etc/apk/repositories
apk add --no-cache curl zsh git 'nodejs~24' 'python3~3.14' tmux zoxide
adduser -D -s /bin/zsh zthxxx
passwd -d zthxxx
install -d -m 755 /home/zthxxx/Project /home/zthxxx/.local/share/zinit/plugins
cp -R /mnt/input/sources/zinit /home/zthxxx/.local/share/zinit/zinit.git
for plugin in ohmyzsh---ohmyzsh zdharma-continuum---fast-syntax-highlighting zsh-users---zsh-completions zsh-users---zsh-autosuggestions; do
  cp -R "/mnt/input/sources/$plugin" "/home/zthxxx/.local/share/zinit/plugins/$plugin"
done
cp -R /mnt/input/theme /home/zthxxx/.local/share/zinit/plugins/zthxxx---jovial
cp /mnt/input/zshrc /home/zthxxx/.zshrc
install -d -m 755 /home/zthxxx/.config
cp /mnt/image/terminal-ready.zsh /home/zthxxx/.config/jovial-preview.zsh
printf '\nsource "$HOME/.config/jovial-preview.zsh"\n' >> /home/zthxxx/.zshrc
cp /mnt/image/zprofile /home/zthxxx/.zprofile
cp /mnt/image/zshenv /home/zthxxx/.zshenv
cp /mnt/image/gitconfig /home/zthxxx/.gitconfig
cp /mnt/image/history /home/zthxxx/.zsh_history
cp -R /mnt/image/projects/. /home/zthxxx/Project/
install -m 755 /mnt/image/jovial-shell /usr/local/bin/jovial-shell
install -m 755 /mnt/image/profile-shell /usr/local/bin/jovial-profile-shell
install -d -m 755 /home/zthxxx/.config/jovial-profile
cp /mnt/image/profile.zsh /home/zthxxx/.config/jovial-profile/profile.zsh
cp /mnt/image/profile.zshenv /home/zthxxx/.config/jovial-profile/.zshenv
cp /mnt/image/profile.zshrc /home/zthxxx/.config/jovial-profile/.zshrc
for mode in full lean minimal; do
  cp "/mnt/input/zshrc-$mode" "/home/zthxxx/.config/jovial-profile/$mode.zsh"
done
printf '%s\n' /bin/zsh >> /etc/shells

for project in node-demo python-demo git-demo; do
  dir="/home/zthxxx/Project/$project"
  git -C "$dir" -c init.defaultBranch=main init -q
  git -C "$dir" -c user.name=zthxxx -c user.email=demo@jovial.local add .
  git -C "$dir" -c user.name=zthxxx -c user.email=demo@jovial.local commit -qm 'feat: add greeting demo'
done
git -C /home/zthxxx/Project/node-demo checkout -qb feat/greeting
git -C /home/zthxxx/Project/git-demo checkout -qb feat/preview
printf 'Preview the Git prompt.\n' >> /home/zthxxx/Project/git-demo/greeting.txt
printf '\nTry editing the greeting and watching the Git prompt.\n' >> /home/zthxxx/Project/node-demo/README.md
printf 'Ideas for the next greeting.\n' > /home/zthxxx/Project/python-demo/notes.txt
python3 -m venv --without-pip /home/zthxxx/Project/python-demo/venv

chown -R zthxxx:zthxxx /home/zthxxx
# Preloaded sources bypass Zinit's clone hook, so register their completions explicitly.
# zinit@d7b10fc: https://github.com/zdharma-continuum/zinit/blob/d7b10fcab51ea034aa7df5d241604b3e6bf46449/zinit.zsh#L3147
su -l zthxxx -c 'zsh -ic "zinit creinstall -q zsh-users/zsh-completions && zinit creinstall -q zdharma-continuum/fast-syntax-highlighting && rm -f ~/.zcompdump* && autoload -Uz compinit && compinit"'

for mode in full lean minimal; do
  cp /home/zthxxx/.zcompdump "/home/zthxxx/.config/jovial-profile/$mode.zcompdump"
done
chown -R zthxxx:zthxxx /home/zthxxx/.config/jovial-profile

apk info -v > /etc/jovial-packages.txt
rm -rf /root/.cache /root/.ash_history /var/cache/apk/* /tmp/*
printf '\nJOVIAL_IMAGE_PROVISIONED\n'
