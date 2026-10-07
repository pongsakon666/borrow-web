import { Button, Modal } from 'antd'
import { CheckCircleOutlined, DeleteOutlined, SaveOutlined } from '@ant-design/icons'
import type { ReactNode } from 'react'

/** confirm = ติ๊กเขียว + ปุ่มม่วง · draft = ไอคอนบันทึก + ปุ่มม่วง · danger = ถังขยะแดง + ปุ่มแดงอยู่ซ้าย */
export type ConfirmVariant = 'confirm' | 'draft' | 'danger'

const ICON: Record<ConfirmVariant, ReactNode> = {
  confirm: <CheckCircleOutlined />,
  draft: <SaveOutlined />,
  danger: <DeleteOutlined />,
}

interface ConfirmModalProps {
  open: boolean
  variant?: ConfirmVariant
  title: ReactNode
  description?: ReactNode
  okText?: string
  cancelText?: string
  loading?: boolean
  onOk: () => void
  onCancel: () => void
  testId?: string
}

/** modal ยืนยัน 400px ตามดีไซน์ (ยืนยันบันทึก / บันทึกฉบับร่าง / ยกเลิก-ลบ) */
export function ConfirmModal({
  open,
  variant = 'confirm',
  title,
  description,
  okText,
  cancelText = 'ยกเลิก',
  loading = false,
  onOk,
  onCancel,
  testId = 'confirm-modal',
}: ConfirmModalProps) {
  const isDanger = variant === 'danger'
  const ok = (
    <Button
      key="ok"
      className={`confirm-modal__btn ${isDanger ? 'is-danger' : 'is-primary'}`}
      loading={loading}
      onClick={onOk}
      data-testid={`${testId}-ok`}
    >
      {okText ?? (isDanger ? 'ลบ' : 'ยืนยัน')}
    </Button>
  )
  const cancel = (
    <Button
      key="cancel"
      className="confirm-modal__btn"
      onClick={onCancel}
      disabled={loading}
      data-testid={`${testId}-cancel`}
    >
      {cancelText}
    </Button>
  )

  return (
    <Modal
      open={open}
      onCancel={onCancel}
      footer={null}
      width={400}
      centered
      className="confirm-modal"
      destroyOnHidden
    >
      <div data-testid={testId}>
        <span className={`confirm-modal__icon is-${variant}`}>{ICON[variant]}</span>
        <h3 className="confirm-modal__title">{title}</h3>
        {description && <p className="confirm-modal__desc">{description}</p>}
        <div className="confirm-modal__actions">{isDanger ? [ok, cancel] : [cancel, ok]}</div>
      </div>
    </Modal>
  )
}
