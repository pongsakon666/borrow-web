import type { ReactNode } from 'react'

interface PageHeaderProps {
  title: ReactNode
  subtitle?: ReactNode
  /** ปุ่ม/ช่องค้นหาชิดขวา */
  actions?: ReactNode
  /** 'lg' = หัวข้อ 32px (Add Product / Borrow form) · 'md' = 24px (หน้าตาราง) */
  size?: 'md' | 'lg'
  testId?: string
}

/** หัวหน้าเพจ: ชื่อหน้า + คำอธิบาย ซ้าย · action ขวา */
export function PageHeader({ title, subtitle, actions, size = 'md', testId }: PageHeaderProps) {
  return (
    <div className={`page-head page-head--${size}`} data-testid={testId}>
      <div className="page-head__text">
        <h1 className="page-head__title">{title}</h1>
        {subtitle && <p className="page-head__subtitle">{subtitle}</p>}
      </div>
      {actions && <div className="page-head__actions">{actions}</div>}
    </div>
  )
}
