import type { ReactNode } from 'react'
import { TONE, type Tone } from '@/app/theme'

interface StatusPillProps {
  tone: Tone
  children: ReactNode
  /** 'pill' = มุมมน 12 (สถานะ) · 'tag' = มุม 4 (ประเภท/หมวด) */
  shape?: 'pill' | 'tag'
  testId?: string
}

/** ป้ายสถานะพื้นโปร่ง 10% + ตัวอักษรสีเข้ม เช่น "รอรับของ" "จ่ายแล้ว" */
export function StatusPill({ tone, children, shape = 'pill', testId }: StatusPillProps) {
  const { bg, fg } = TONE[tone]
  return (
    <span
      className={`status-pill status-pill--${shape}`}
      style={{ background: bg, color: fg }}
      data-testid={testId}
    >
      {children}
    </span>
  )
}
