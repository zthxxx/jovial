export const demos = [
  { name: 'Git at a glance', detail: 'Branch & working tree', command: 'cd ~/Project/node-demo && git status --short' },
  { name: 'Node.js project', detail: 'Automatic version detection', command: 'cd ~/Project/node-demo && node index.js' },
  { name: 'Python environment', detail: 'Virtualenv in your prompt', command: 'cd ~/Project/python-demo && source venv/bin/activate && python hello.py' },
  { name: 'Take a look around', detail: 'Your preinstalled workspace', command: 'cd ~/Project && ls -la' },
] as const
