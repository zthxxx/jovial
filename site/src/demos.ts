export interface CommandPreset {
  name: string
  detail: string
  command: string
}

export interface TerminalPreset {
  key: 'project' | 'python' | 'node' | 'git'
  name: string
  path: string
  label: string
  commands: readonly CommandPreset[]
}

export const presets: Record<TerminalPreset['key'], TerminalPreset> = {
  project: {
    key: 'project', name: 'Project', path: '/home/zthxxx/Project', label: '~/Project',
    commands: [
      { name: 'Look around', detail: 'List your demo projects', command: 'ls -la' },
      { name: 'Python project', detail: 'Change directory', command: 'cd ~/Project/python-demo' },
      { name: 'Node.js project', detail: 'Change directory', command: 'cd ~/Project/node-demo' },
      { name: 'Git project', detail: 'Change directory', command: 'cd ~/Project/git-demo' },
    ],
  },
  python: {
    key: 'python', name: 'Python', path: '/home/zthxxx/Project/python-demo', label: '~/Project/python-demo',
    commands: [
      { name: 'Run Python', detail: 'A greeting from Python', command: 'python hello.py' },
      { name: 'Activate venv', detail: 'See the environment in your prompt', command: 'source venv/bin/activate' },
      { name: 'Git status', detail: 'Inspect the working tree', command: 'git status --short' },
      { name: 'Read the example', detail: 'Show the Python source', command: 'cat hello.py' },
    ],
  },
  node: {
    key: 'node', name: 'Node.js', path: '/home/zthxxx/Project/node-demo', label: '~/Project/node-demo',
    commands: [
      { name: 'Run Node.js', detail: 'A greeting from Node.js', command: 'node index.js' },
      { name: 'Project settings', detail: 'Show package.json', command: 'cat package.json' },
      { name: 'Git status', detail: 'Inspect the working tree', command: 'git status --short' },
      { name: 'Read the example', detail: 'Show the JavaScript source', command: 'cat index.js' },
    ],
  },
  git: {
    key: 'git', name: 'Git', path: '/home/zthxxx/Project/git-demo', label: '~/Project/git-demo',
    commands: [
      { name: 'Working tree', detail: 'See the changed file', command: 'git status --short' },
      { name: 'Show changes', detail: 'Inspect the diff', command: 'git --no-pager diff' },
      { name: 'Commit history', detail: 'Show recent commits', command: 'git --no-pager log --oneline -5' },
      { name: 'Branches', detail: 'See the current branch', command: 'git --no-pager branch' },
    ],
  },
}

export const defaultPresets = [presets.project, presets.python, presets.node, presets.git]
