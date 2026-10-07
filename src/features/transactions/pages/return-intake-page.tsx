import { useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { App, AutoComplete, Button, Checkbox, Empty, Input, Select, Spin } from 'antd'
import type { InputRef } from 'antd'
import {
  PlusCircleOutlined,
  QrcodeOutlined,
  RightOutlined,
  SearchOutlined,
  UnorderedListOutlined,
  UserOutlined,
} from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { getErrorMessage } from '@/shared/api/http'
import { PageHeader } from '@/shared/components/page-header'
import { ConfirmModal } from '@/shared/components/confirm-modal'
import { UserAvatar } from '@/shared/components/user-avatar'
import { dashboardApi } from '@/features/dashboard/api/dashboard.api'
import { equipmentApi } from '@/features/equipment/api/equipment.api'
import type { UserProfile } from '@/features/auth/types/auth.types'
import { transactionsApi } from '../api'
import type { Transaction } from '../types'
import {
  CONDITION_OPTIONS,
  REASON_OPTIONS,
  type ReturnCondition,
  buildReturnNote,
  conditionLabel,
  formatThaiDate,
  needsInspection,
} from '../return-helpers'
import '../return.css'

/** แถวทรัพย์สินที่จะรับคืน — มาจากรายการยืมที่ยังไม่คืน หรือเพิ่มเองจากรหัสทรัพย์สิน */
interface IntakeRow {
  key: string
  borrow?: Transaction
  equipmentId: string
  equipmentName: string
  equipmentCode: string
  quantity: number
  category?: string
  department?: string
}

interface RowState {
  selected: boolean
  condition: ReturnCondition
  reason?: string
}

interface Draft {
  returner: UserProfile | null
  extras: IntakeRow[]
  states: Record<string, Partial<RowState>>
  note: string
}

const DRAFT_KEY = 'return-intake-draft'
const DEFAULT_STATE: RowState = { selected: true, condition: 'normal' }

/** รายการยืมที่ถือว่า "ยังอยู่กับผู้ยืม" */
const OPEN_BORROW = new Set(['approved', 'in_progress'])

function loadDraft(): Draft | null {
  try {
    const raw = localStorage.getItem(DRAFT_KEY)
    return raw ? (JSON.parse(raw) as Draft) : null
  } catch {
    return null
  }
}

function clearDraft() {
  try {
    localStorage.removeItem(DRAFT_KEY)
  } catch {
    // ignore
  }
}

/** หน้า "ขั้นตอนรับคืนของใช้และทรัพย์สินออฟฟิศ" (/return/new) */
export function ReturnIntakePage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { message } = App.useApp()
  const assetInputRef = useRef<InputRef>(null)

  const [draft] = useState(loadDraft)
  const [keyword, setKeyword] = useState(draft?.returner?.name ?? '')
  const [returner, setReturner] = useState<UserProfile | null>(draft?.returner ?? null)
  const [extras, setExtras] = useState<IntakeRow[]>(draft?.extras ?? [])
  const [states, setStates] = useState<Record<string, Partial<RowState>>>(draft?.states ?? {})
  const [note, setNote] = useState(draft?.note ?? '')
  const [assetCode, setAssetCode] = useState('')
  const [modal, setModal] = useState<'confirm' | 'draft' | 'cancel' | null>(null)

  const members = useQuery({
    queryKey: ['users', 'members', 100],
    queryFn: () => dashboardApi.members(100),
    staleTime: 5 * 60_000,
  })
  const equipment = useQuery({
    queryKey: ['equipment', 'lookup', 100],
    queryFn: () => equipmentApi.list({ limit: 100 }),
    staleTime: 5 * 60_000,
  })

  // รายการยืมของผู้คืนที่ยังไม่คืน → กลายเป็นแถวในตาราง
  const borrows = useQuery({
    queryKey: ['transactions', 'open-borrows', returner?.id],
    enabled: !!returner,
    queryFn: async () => {
      const res = await transactionsApi.list({
        type: 'borrow',
        search: returner!.name,
        limit: 100,
      })
      return res.items.filter((t) => t.userId === returner!.id && OPEN_BORROW.has(t.status))
    },
  })

  const equipmentById = useMemo(
    () => new Map((equipment.data?.items ?? []).map((e) => [e.id, e])),
    [equipment.data],
  )

  const rows: IntakeRow[] = useMemo(() => {
    const fromBorrows = (borrows.data ?? []).map<IntakeRow>((t) => ({
      key: t.id,
      borrow: t,
      equipmentId: t.equipmentId,
      equipmentName: t.equipmentName,
      equipmentCode: t.equipmentCode,
      quantity: t.quantity,
      category: equipmentById.get(t.equipmentId)?.category,
      department: equipmentById.get(t.equipmentId)?.department,
    }))
    return [...fromBorrows, ...extras]
  }, [borrows.data, extras, equipmentById])

  const stateOf = (key: string): RowState => ({ ...DEFAULT_STATE, ...states[key] })
  const patchRow = (key: string, patch: Partial<RowState>) =>
    setStates((prev) => ({ ...prev, [key]: { ...prev[key], ...patch } }))

  const selectedRows = rows.filter((r) => stateOf(r.key).selected)
  const flagged = selectedRows.filter((r) => stateOf(r.key).condition !== 'normal')
  const allChecked = selectedRows.length > 0 && selectedRows.every((r) => !!stateOf(r.key).reason)
  const ready = !!returner && allChecked

  // วันที่แจกจ่าย = วันที่ยืมรายการแรกสุดที่ยังค้างอยู่
  const issuedAt = useMemo(() => {
    const dates = (borrows.data ?? []).map((t) => t.occurredAt).sort()
    return dates[0] ?? null
  }, [borrows.data])
  const departments = [...new Set(rows.map((r) => r.department).filter(Boolean))].join(', ')

  const matches = useMemo(() => {
    const text = keyword.trim().toLowerCase()
    const list = members.data ?? []
    if (!text) return list
    return list.filter(
      (m) => m.name.toLowerCase().includes(text) || m.email.toLowerCase().includes(text),
    )
  }, [keyword, members.data])

  const pickReturner = (user: UserProfile) => {
    setReturner(user)
    setKeyword(user.name)
    setStates({})
  }

  const searchReturner = () => {
    const found = matches[0]
    if (found) pickReturner(found)
    else message.warning('ไม่พบผู้ใช้งานที่ค้นหา')
  }

  // ดึงข้อมูลทรัพย์สินจากรหัส — ถ้าอยู่ในรายการยืมอยู่แล้วให้ติ๊กเลือก ไม่งั้นเพิ่มเป็นแถวใหม่
  const fetchAsset = useMutation({
    mutationFn: async (code: string) => {
      const lower = code.toLowerCase()
      const existing = rows.find((r) => r.equipmentCode.toLowerCase() === lower)
      if (existing) return { existing }
      const res = await equipmentApi.list({ search: code, limit: 10 })
      const item = res.items.find((e) => e.code.toLowerCase() === lower) ?? res.items[0]
      return { item }
    },
    onSuccess: ({ existing, item }) => {
      if (existing) {
        patchRow(existing.key, { selected: true })
        message.success(`เลือก ${existing.equipmentName} แล้ว`)
      } else if (item) {
        setExtras((prev) => [
          ...prev,
          {
            key: `extra-${item.id}-${Date.now()}`,
            equipmentId: item.id,
            equipmentName: item.name,
            equipmentCode: item.code,
            quantity: 1,
            category: item.category,
            department: item.department,
          },
        ])
        message.success(`เพิ่ม ${item.name} แล้ว`)
      } else {
        message.warning('ไม่พบทรัพย์สินจากรหัสนี้')
        return
      }
      setAssetCode('')
    },
    onError: (error) => message.error(getErrorMessage(error, 'ดึงข้อมูลทรัพย์สินไม่สำเร็จ')),
  })

  const submitAsset = () => {
    const code = assetCode.trim()
    if (!code) {
      message.info('กรอกรหัสทรัพย์สินก่อน')
      assetInputRef.current?.focus()
      return
    }
    fetchAsset.mutate(code)
  }

  /**
   * ยืนยันรับคืน: รายการยืมเดิม → complete, แล้วสร้างรายการ type=return ต่อชิ้น
   * (API ไม่มีฟิลด์สภาพ/ผู้คืน จึงเขียนลง note) ชำรุด/สูญหาย → in_progress ให้เจ้าหน้าที่ตรวจต่อ
   */
  const confirmReturn = useMutation({
    mutationFn: async () => {
      for (const row of selectedRows) {
        const state = stateOf(row.key)
        if (row.borrow) await transactionsApi.updateStatus(row.borrow.id, 'complete')
        const created = await transactionsApi.create({
          type: 'return',
          equipmentId: row.equipmentId,
          quantity: row.quantity,
          note: buildReturnNote({
            condition: conditionLabel(state.condition),
            reason: state.reason,
            returner: returner?.name,
            ref: row.borrow?.code,
            remark: note.trim() || undefined,
          }),
        })
        if (needsInspection(state.condition)) {
          await transactionsApi.updateStatus(created.id, 'in_progress')
        }
      }
    },
    onSuccess: () => {
      clearDraft()
      void queryClient.invalidateQueries({ queryKey: ['transactions'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      void queryClient.invalidateQueries({ queryKey: ['equipment'] })
      message.success(`รับคืนแล้ว ${selectedRows.length} รายการ`)
      setModal(null)
      navigate('/return')
    },
    onError: (error) => {
      void queryClient.invalidateQueries({ queryKey: ['transactions'] })
      message.error(getErrorMessage(error, 'บันทึกการรับคืนไม่สำเร็จ'))
    },
  })

  // ไม่มี API ฉบับร่าง — เก็บในเบราว์เซอร์แล้วโหลดกลับเมื่อเปิดหน้านี้อีกครั้ง
  const saveDraft = () => {
    try {
      const data: Draft = { returner, extras, states, note }
      localStorage.setItem(DRAFT_KEY, JSON.stringify(data))
      message.success('บันทึกฉบับร่างแล้ว')
    } catch {
      message.error('บันทึกฉบับร่างไม่สำเร็จ')
    }
    setModal(null)
  }

  const cancelIntake = () => {
    clearDraft()
    setModal(null)
    navigate('/return')
  }

  const statusText = !returner
    ? { text: 'รอระบุผู้คืน', muted: true }
    : selectedRows.length === 0
      ? { text: 'ยังไม่เลือกทรัพย์สิน', muted: true }
      : !allChecked
        ? { text: 'รอตรวจสภาพ', muted: true }
        : { text: 'พร้อมส่งคืนคลัง', muted: false }

  return (
    <div className="page ret-intake" data-testid="return-intake-page">
      <div className="ret-intake__head">
        <PageHeader
          title="ขั้นตอนรับคืนของใช้และทรัพย์สินออฟฟิศจากผู้ใช้งาน / พนักงาน"
          subtitle="รับคืนของใช้และทรัพย์สินออฟฟิศ (Asset Return Intake)"
        />
      </div>

      <div className="ret-intake__grid">
        <div className="ret-intake__col">
          {/* ระบุผู้คืน */}
          <section className="ret-panel" data-testid="return-returner-panel">
            <header className="ret-panel__head">
              <h2>
                <UserOutlined /> ระบุผู้คืน (Returner)
              </h2>
              <span>1 คนสามารถคืนทรัพย์สินหลายรายการใน 1 รายการคืน</span>
            </header>

            <div className="ret-inputs">
              <AutoComplete
                className="ret-inputs__grow"
                value={keyword}
                options={matches.slice(0, 8).map((m) => ({
                  value: m.id,
                  label: (
                    <span className="ret-option">
                      <strong>{m.name}</strong>
                      <small>{m.email}</small>
                    </span>
                  ),
                }))}
                onSelect={(id: string) => {
                  const user = members.data?.find((m) => m.id === id)
                  if (user) pickReturner(user)
                }}
                onChange={(value: string) => {
                  // ตอนเลือกตัวเลือก value จะเป็น id — ปล่อยให้ onSelect จัดการ
                  if (!members.data?.some((m) => m.id === value)) setKeyword(value)
                }}
              >
                <Input
                  className="ret-input"
                  data-testid="return-returner-search"
                  prefix={<SearchOutlined />}
                  placeholder="ค้นหาชื่อผู้ใช้งาน / รหัสพนักงาน"
                  onPressEnter={searchReturner}
                />
              </AutoComplete>
              <Button
                className="btn-pink"
                data-testid="return-returner-submit"
                loading={members.isLoading}
                onClick={searchReturner}
              >
                ค้นหา
              </Button>
            </div>

            {returner ? (
              <>
                <div className="ret-returner" data-testid="return-returner-selected">
                  <UserAvatar name={returner.name} size={42} />
                  <span className="ret-returner__text">
                    <small>{returner.email}</small>
                    <strong>{returner.name}</strong>
                  </span>
                  <button
                    type="button"
                    className="ret-returner__change"
                    aria-label="เปลี่ยนผู้คืน"
                    title="เปลี่ยนผู้คืน"
                    onClick={() => {
                      setReturner(null)
                      setKeyword('')
                      setStates({})
                    }}
                  >
                    <RightOutlined />
                  </button>
                </div>
                <div className="ret-returner__meta">
                  <span>เบอร์โทรภายใน: -</span>
                  <span>วันที่แจกจ่าย: {formatThaiDate(issuedAt)}</span>
                </div>
              </>
            ) : (
              <p className="ret-placeholder">ยังไม่ได้เลือกผู้คืน — ค้นหาจากชื่อหรืออีเมล</p>
            )}
          </section>

          {/* สแกน / เพิ่มทรัพย์สิน */}
          <section className="ret-panel" data-testid="return-asset-panel">
            <header className="ret-panel__head">
              <h2>
                <UnorderedListOutlined /> สแกนหรือเพิ่มทรัพย์สินหลายรายการ
              </h2>
              <span>ตรวจสภาพแต่ละรายการก่อนยืนยันการคืน</span>
            </header>

            <div className="ret-inputs">
              <Input
                ref={assetInputRef}
                className="ret-input ret-inputs__code"
                data-testid="return-asset-code"
                prefix={<SearchOutlined />}
                placeholder="ASSET-2024-998241"
                value={assetCode}
                onChange={(e) => setAssetCode(e.target.value)}
                onPressEnter={submitAsset}
              />
              <Button
                className="ret-qr-btn"
                icon={<QrcodeOutlined />}
                data-testid="return-asset-scan"
                onClick={() => {
                  message.info('ยังไม่รองรับการสแกนจากกล้อง — กรอกรหัสบนแท็กทรัพย์สินแทน')
                  assetInputRef.current?.focus()
                }}
              >
                สแกน QR Code บนแท็กทรัพย์สิน
              </Button>
              <Button
                className="btn-pink"
                data-testid="return-asset-fetch"
                loading={fetchAsset.isPending}
                onClick={submitAsset}
              >
                ดึงข้อมูลทรัพย์สิน
              </Button>
            </div>

            <button
              type="button"
              className="ret-add-link"
              data-testid="return-asset-add"
              onClick={() => {
                message.info('กรอกรหัสทรัพย์สินที่ต้องการเพิ่ม แล้วกด "ดึงข้อมูลทรัพย์สิน"')
                assetInputRef.current?.focus()
              }}
            >
              <PlusCircleOutlined /> เพิ่มทรัพย์สินนอกเหนือรายการดั้งเดิม
            </button>

            <div className="ret-assets" data-testid="return-asset-table">
              <div className="ret-assets__head">
                <span />
                <span>รายละเอียดทรัพย์สิน</span>
                <span>สภาพทรัพย์สินที่รับคืน</span>
                <span>เหตุผลการคืน / สาเหตุ</span>
              </div>

              {borrows.isFetching && rows.length === 0 ? (
                <div className="ret-assets__empty">
                  <Spin />
                </div>
              ) : rows.length === 0 ? (
                <Empty
                  className="ret-assets__empty"
                  image={Empty.PRESENTED_IMAGE_SIMPLE}
                  description={
                    returner
                      ? 'ไม่มีทรัพย์สินค้างคืนของผู้ใช้งานนี้'
                      : 'เลือกผู้คืนเพื่อดึงรายการทรัพย์สิน'
                  }
                />
              ) : (
                rows.map((row) => {
                  const state = stateOf(row.key)
                  return (
                    <div
                      key={row.key}
                      className={`ret-assets__row${state.selected ? '' : ' is-off'}`}
                      data-testid="return-asset-row"
                    >
                      <span className="ret-assets__check">
                        <Checkbox
                          checked={state.selected}
                          aria-label={`เลือก ${row.equipmentName}`}
                          onChange={(e) => patchRow(row.key, { selected: e.target.checked })}
                          data-testid="return-asset-check"
                        />
                      </span>
                      <div className="ret-assets__info">
                        <strong>
                          {row.equipmentName}
                          {row.quantity > 1 && ` × ${row.quantity}`}
                        </strong>
                        <small>รหัสทรัพย์สิน: {row.equipmentCode}</small>
                        <small>ประเภท: {row.category ?? '-'}</small>
                        <small>ผู้รับผิดชอบ: {row.department || '-'}</small>
                        {!row.borrow && <small className="is-extra">เพิ่มนอกรายการยืม</small>}
                      </div>
                      <Select
                        className="ret-assets__select"
                        value={state.condition}
                        options={CONDITION_OPTIONS}
                        disabled={!state.selected}
                        onChange={(value) => patchRow(row.key, { condition: value })}
                        data-testid="return-asset-condition"
                      />
                      <Select
                        className="ret-assets__select"
                        value={state.reason}
                        placeholder="เลือกเหตุผล"
                        options={REASON_OPTIONS}
                        disabled={!state.selected}
                        onChange={(value) => patchRow(row.key, { reason: value })}
                        data-testid="return-asset-reason"
                      />
                    </div>
                  )
                })
              )}
            </div>
          </section>

          <section className="ret-panel">
            <h2 className="ret-panel__title">บันทึกข้อความเพิ่มเติมจากเจ้าหน้าที่คลังอุปกรณ์</h2>
            <Input.TextArea
              className="ret-note"
              data-testid="return-note"
              rows={3}
              maxLength={500}
              placeholder="เช่น ตรวจสอบแล้ว อุปกรณ์ครบกล่อง มีรอยขีดข่วนเล็กน้อย"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
          </section>
        </div>

        <aside className="ret-intake__col is-side">
          <section className="ret-panel">
            <h2 className="ret-panel__title">ข้อมูลผู้ใช้งานและทรัพย์สิน</h2>
            <dl className="ret-kv">
              <div>
                <dt>ชื่อผู้ใช้งาน</dt>
                <dd className="is-strong">{returner?.name ?? '-'}</dd>
              </div>
              <div>
                <dt>เบอร์โทรภายใน</dt>
                <dd>-</dd>
              </div>
              <div>
                <dt>วันที่แจกจ่าย</dt>
                <dd>{formatThaiDate(issuedAt)}</dd>
              </div>
              <div>
                <dt>หน่วยงาน</dt>
                <dd className="is-link">{departments || '-'}</dd>
              </div>
            </dl>
          </section>

          <section className="ret-panel" data-testid="return-summary">
            <h2 className="ret-panel__title">สรุปการรับคืน (Return Summary)</h2>
            <dl className="ret-kv">
              <div>
                <dt>จำนวนรายการทรัพย์สินที่รับคืน ({selectedRows.length} รายการ)</dt>
                <dd>{selectedRows.length} รายการ</dd>
              </div>
              <div>
                <dt>หมายเหตุการตรวจสภาพ</dt>
                <dd className={flagged.length ? 'is-warn' : undefined}>
                  {flagged.length
                    ? `มี ${flagged.length} รายการ${conditionLabel(stateOf(flagged[0].key).condition)}`
                    : 'ไม่มี'}
                </dd>
              </div>
              <div>
                <dt>สถานะการตรวจสอบ</dt>
                <dd>{allChecked ? 'ตรวจสอบแล้ว' : 'รอตรวจสอบ'}</dd>
              </div>
            </dl>
            <hr className="ret-divider" />
            <div className="ret-total">
              <span>สถานะการรับคืน</span>
              <strong
                className={statusText.muted ? 'is-muted' : undefined}
                data-testid="return-status"
              >
                {statusText.text}
              </strong>
            </div>
            <div className="ret-transfer">
              <small>สถานะการโอนสิทธิ์ทรัพย์สิน</small>
              <strong>รอโอนสิทธิ์ให้คลังอุปกรณ์</strong>
              <span>ผู้รับผิดชอบ: เจ้าหน้าที่คลังอุปกรณ์</span>
            </div>
          </section>

          <div className="ret-actions">
            <Button
              type="primary"
              className="ret-actions__confirm"
              data-testid="return-confirm"
              icon={<RightOutlined />}
              iconPlacement="end"
              disabled={!ready}
              onClick={() => setModal('confirm')}
            >
              ยืนยันรับคืน
            </Button>
            <div className="ret-actions__row">
              <Button
                className="ret-actions__draft"
                data-testid="return-draft"
                onClick={() => setModal('draft')}
              >
                บันทึกฉบับร่าง
              </Button>
              <Button
                className="ret-actions__cancel"
                data-testid="return-cancel"
                onClick={() => setModal('cancel')}
              >
                ยกเลิก
              </Button>
            </div>
          </div>
        </aside>
      </div>

      <ConfirmModal
        open={modal === 'confirm'}
        variant="confirm"
        title="ต้องการยืนยันรับคืน ?"
        description="ตรวจสอบรายละเอียดทรัพย์สินและข้อมูลผู้รับโอน ก่อนยืนยันการรับคืนและโอนสิทธิ์"
        loading={confirmReturn.isPending}
        onOk={() => confirmReturn.mutate()}
        onCancel={() => setModal(null)}
        testId="return-confirm-modal"
      />
      <ConfirmModal
        open={modal === 'draft'}
        variant="draft"
        title="ต้องการบันทึกเป็นฉบับร่างใช่ไหม?"
        description="ข้อมูลที่กรอกไว้จะถูกบันทึก และคุณสามารถกลับมาแก้ไขได้ภายหลัง"
        onOk={saveDraft}
        onCancel={() => setModal(null)}
        testId="return-draft-modal"
      />
      <ConfirmModal
        open={modal === 'cancel'}
        variant="danger"
        title="ต้องการยกเลิกการยืมคืน ?"
        description="ข้อมูลที่กรอกไว้จะถูกลบ และไม่สามารถกู้คืนได้"
        onOk={cancelIntake}
        onCancel={() => setModal(null)}
        testId="return-cancel-modal"
      />
    </div>
  )
}
