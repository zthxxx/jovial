import gitStates from '../../docs/jovial-git-actions.png?url'
import developmentEnvironments from '../../docs/jovial-develop-env-detect.png?url'
import executionTime from '../../docs/jovial-exec-elapsed.png?url'
import prompt from '../../docs/jovial.png?url'
import responsivePrompt from '../../docs/jovial-responsive-desigin.mp4?url'

const images = {
  'feature-git-image': gitStates,
  'feature-environment-image': developmentEnvironments,
  'feature-elapsed-image': executionTime,
}
for (const [id, source] of Object.entries(images)) {
  document.querySelector<HTMLImageElement>(`#${id}`)!.src = source
}
const video = document.querySelector<HTMLVideoElement>('#feature-responsive-video')!
video.poster = prompt
video.src = responsivePrompt
video.load()

// Keep the responsive demonstration from competing with the live shell offscreen.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)')
new IntersectionObserver(([entry]) => {
  if (!entry?.isIntersecting) video.pause()
  else if (!reducedMotion.matches) void video.play().catch(() => {})
}, { threshold: 0.25 }).observe(video)
