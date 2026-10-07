import type { ReactNode } from 'react'

interface StatCardProps {
  label: ReactNode
  value: ReactNode
  /** ข้อความเล็กท้ายตัวเลข เช่น "มารับตามเวลา" */
  hint?: ReactNode
  /** true = hint เป็นป้ายพื้นเทา (เช่น "อัปเดตเรียลไทม์") */
  hintBadge?: boolean
  /** โทนพื้นการ์ด — สลับม่วงอ่อน/ฟ้าอ่อนตามดีไซน์ */
  tint?: 'lavender' | 'sky'
  testId?: string
  valueTestId?: string
}

/** การ์ดสถิติพื้นสีอ่อน มุมโค้ง 20 (Borrow / Return / Dashboard) */
export function StatCard({
  label,
  value,
  hint,
  hintBadge = false,
  tint = 'lavender',
  testId,
  valueTestId,
}: StatCardProps) {
  return (
    <div className={`stat-card stat-card--${tint}`} data-testid={testId}>
      <span className="stat-card__label">{label}</span>
      <div className="stat-card__row">
        <strong className="stat-card__value" data-testid={valueTestId}>
          {value}
        </strong>
        {hint && <span className={hintBadge ? 'stat-card__badge' : 'stat-card__hint'}>{hint}</span>}
      </div>
    </div>
  )
}
