import type { ReactNode } from 'react'

interface SectionCardProps {
  title?: ReactNode
  /** ป้ายนับจำนวนข้างหัวข้อ เช่น "4 รายการวันนี้" */
  badge?: ReactNode
  badgeTone?: 'purple' | 'pink'
  /** แถบสีแนวตั้งหน้าหัวข้อ */
  accent?: boolean
  extra?: ReactNode
  children: ReactNode
  className?: string
  testId?: string
}

/** กล่องขาวขอบเทา มุมโค้ง 16 · padding 24 — ใช้ครอบตาราง/ฟอร์ม */
export function SectionCard({
  title,
  badge,
  badgeTone = 'purple',
  accent = false,
  extra,
  children,
  className,
  testId,
}: SectionCardProps) {
  return (
    <section className={['section-card', className].filter(Boolean).join(' ')} data-testid={testId}>
      {(title || extra) && (
        <header className="section-card__head">
          <div className="section-card__title">
            {accent && <i className="section-card__accent" />}
            {title && <h2>{title}</h2>}
            {badge && <span className={`section-card__badge is-${badgeTone}`}>{badge}</span>}
          </div>
          {extra && <div className="section-card__extra">{extra}</div>}
        </header>
      )}
      {children}
    </section>
  )
}
