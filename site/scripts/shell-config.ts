export type ShellMode = 'full' | 'lean' | 'minimal'

export function createShellConfigs(example: string): Record<ShellMode, string> {
  const full = example
    .replaceAll(' wait lucid ', ' lucid ')
    .replace('ZINIT[COMPINIT_OPTS]=-C', 'ZINIT[COMPINIT_OPTS]=')
    .replace(/^## https:\/\/github\.com\/zthxxx\/zsh-history-enquirer\n/m, '')
    .replace(/    multisrc='\*\.plugin\.zsh' \\\n        zthxxx\/zsh-history-enquirer \\\n/m, '')
  if (full.includes('zthxxx/zsh-history-enquirer')) throw new Error('Could not remove history-enquirer from the example')
  const lean = full
    .replace('autoload -Uz compinit && compinit', 'autoload -Uz compinit && compinit -C')
    .replace(/zinit light-mode depth=1 lucid for \\\n[\s\S]*?        zsh-users\/zsh-autosuggestions/m,
      'zinit light-mode depth=1 blockf for zsh-users/zsh-completions')
  if (lean.includes('        zdharma-continuum/fast-syntax-highlighting') || lean.includes('        zsh-users/zsh-autosuggestions')) {
    throw new Error('Could not remove interactive enhancement plugins from the lean shell')
  }
  const minimal = `export XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\${HOME}/.config}"
export XDG_DATA_HOME="\${XDG_DATA_HOME:-\${HOME}/.local/share}"
ZINIT_HOME="\${XDG_DATA_HOME}/zinit/zinit.git"
source "\${ZINIT_HOME}/zinit.zsh"
zinit light-mode depth=1 multisrc='*.plugin.zsh' for zthxxx/jovial
`
  return { full, lean, minimal }
}

export function bindProfileCompletionCache(config: string): string {
  return config
    .replace(/^(autoload -Uz compinit && compinit[^\n]*)$/m, '$1 -d "$ZDOTDIR/${JOVIAL_PROFILE_MODE}.zcompdump"')
    .replace(/^(source "\$\{ZINIT_HOME\}\/zinit.zsh")$/m,
      '$1\nZINIT[ZCOMPDUMP_PATH]="$ZDOTDIR/${JOVIAL_PROFILE_MODE}.zcompdump"')
}

export function instrumentShellConfig(config: string): string {
  let omz = 0
  return bindProfileCompletionCache(config)
    .replace(/^(autoload -Uz compinit && compinit.*)$/m, '$1\n_jovial_profile_mark compinit')
    .replace(/^(source "\$\{ZINIT_HOME\}\/zinit.zsh")$/m, '$1\n_jovial_profile_mark zinit')
    .replace(/^(zinit light-mode depth=1 multisrc='\*\.plugin\.zsh' for zthxxx\/jovial)$/m,
      '$1\n_jovial_profile_mark theme')
    .replace(/^(\s+ohmyzsh\/ohmyzsh)$/gm, (match) => `${match}\n_jovial_profile_mark ${omz++ === 0 ? 'omz-libraries' : 'omz-plugins'}`)
    .replace(/^(\s+zsh-users\/zsh-autosuggestions|zinit light-mode depth=1 blockf for zsh-users\/zsh-completions)$/m,
      '$1\n_jovial_profile_mark enhancements') + '\n_jovial_profile_mark zshrc\n'
}
