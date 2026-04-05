export default function GroupSelector({ groups, selectedId, onChange }) {
  if (!groups || groups.length === 0) return null

  return (
    <select
      className="group-selector"
      value={selectedId || ''}
      onChange={e => onChange(e.target.value)}
    >
      {groups.map(g => (
        <option key={g.id} value={g.id}>{g.name}</option>
      ))}
    </select>
  )
}
