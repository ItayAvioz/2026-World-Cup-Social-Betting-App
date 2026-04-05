export default function Flag({ code, size = 40, alt = '' }) {
  if (!code) return <div className="team-placeholder">?</div>
  return (
    <img
      src={`https://flagcdn.com/w${size}/${code}.png`}
      alt={alt}
      onError={e => { e.currentTarget.style.display = 'none' }}
    />
  )
}
