/** ภาพประกอบหน้า login — เส้นคลื่นสีขาวบนพื้นเทาอมฟ้า (แทนรูปภาพในดีไซน์) */
export function WaveArt() {
  const lines = Array.from({ length: 34 }, (_, i) => {
    const x = -260 + i * 34
    return `M${x} -40 C${x + 420} 220 ${x - 180} 560 ${x + 260} 820 S${x + 120} 1180 ${x + 420} 1260`
  })

  return (
    <svg
      className="auth-visual__art"
      viewBox="0 0 672 1076"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
    >
      <defs>
        <radialGradient id="wave-bg" cx="30%" cy="15%" r="95%">
          <stop offset="0" stopColor="#f1f3f8" />
          <stop offset=".55" stopColor="#d9dde8" />
          <stop offset="1" stopColor="#b9bfcd" />
        </radialGradient>
        <linearGradient id="wave-fade" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#ffffff" stopOpacity=".35" />
          <stop offset=".6" stopColor="#ffffff" stopOpacity=".95" />
          <stop offset="1" stopColor="#ffffff" stopOpacity=".6" />
        </linearGradient>
      </defs>
      <rect width="672" height="1076" fill="url(#wave-bg)" />
      <g fill="none" stroke="url(#wave-fade)" strokeWidth="2.2">
        {lines.map((d) => (
          <path key={d} d={d} />
        ))}
      </g>
      <g fill="none" stroke="#9aa1b3" strokeOpacity=".35" strokeWidth="1.4">
        {lines.slice(0, 8).map((d) => (
          <path key={d} d={d} transform="translate(-90 -260) rotate(-8)" />
        ))}
      </g>
    </svg>
  )
}
