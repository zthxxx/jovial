// GitHub REST API: public repository metadata, stargazers_count.
// https://docs.github.com/en/rest/repos/repos#get-a-repository
export async function loadGitHubStars() {
  const count = document.getElementById('github-star-count')
  const link = document.getElementById('github-link')
  if (!count || !link) return
  try {
    const response = await fetch('https://api.github.com/repos/zthxxx/jovial', {
      headers: { Accept: 'application/vnd.github+json' },
      signal: AbortSignal.timeout(5000),
    })
    if (!response.ok) return
    const repository = await response.json() as { stargazers_count?: number }
    const stars = repository.stargazers_count
    if (typeof stars !== 'number' || !Number.isSafeInteger(stars) || stars < 0) return
    count.textContent = new Intl.NumberFormat('en').format(stars)
    link.setAttribute('aria-label', `Jovial on GitHub, ${count.textContent} stars`)
  } catch { /* The link remains a working Star action when GitHub is unavailable. */ }
}
