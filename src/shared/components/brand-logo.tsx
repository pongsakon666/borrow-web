interface BrandLogoProps {
  size?: number
  /** true = ใช้บนพื้นเข้ม (โลโก้เป็นสีขาว) */
  inverse?: boolean
}

/** โลโก้ RP.Rent — กล่องพัสดุเส้นสีน้ำเงิน (ไอคอน "package" ในดีไซน์) */
export function BrandLogo({ size = 32, inverse = false }: BrandLogoProps) {
  const fg = inverse ? '#ffffff' : '#1470ff'

  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-label="RP.Rent">
      <path
        d="M16 3.5 27 9.5v13L16 28.5 5 22.5v-13L16 3.5Z"
        stroke={fg}
        strokeWidth="2"
        strokeLinejoin="round"
      />
      <path d="M5 9.5 16 15.5l11-6M16 15.5v13" stroke={fg} strokeWidth="2" strokeLinejoin="round" />
      <path d="m10.5 6.5 11 6" stroke={fg} strokeWidth="2" strokeLinejoin="round" />
    </svg>
  )
}
