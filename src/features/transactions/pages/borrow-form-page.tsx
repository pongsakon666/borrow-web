import '../borrow.css'
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { App, AutoComplete, Button, DatePicker, Form, Input, InputNumber, Modal, Select } from 'antd'
import type { TextAreaRef } from 'antd/es/input/TextArea'
import {
  CalendarOutlined,
  DownOutlined,
  ExclamationCircleOutlined,
  FolderAddOutlined,
  FolderOutlined,
  ItalicOutlined,
  LinkOutlined,
  MinusOutlined,
  PlusOutlined,
  ScanOutlined,
  TagOutlined,
  UnderlineOutlined,
  UnorderedListOutlined,
  UserOutlined,
  BgColorsOutlined,
  FontSizeOutlined,
} from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import dayjs, { type Dayjs } from 'dayjs'
import { useAuthStore } from '@/app/store/auth.store'
import { getErrorMessage } from '@/shared/api/http'
import { ConfirmModal, type ConfirmVariant } from '@/shared/components/confirm-modal'
import { PageHeader } from '@/shared/components/page-header'
import { equipmentApi } from '@/features/equipment/api/equipment.api'
import type { Equipment } from '@/features/equipment/types/equipment.types'
import { transactionsApi } from '../api'
import { BORROW_CHANNELS, buildBorrowNote, formatThaiDateTime, type BorrowChannel } from '../borrow-meta'

const DRAFT_KEY = 'borrow-form-draft'

const ROLE_LABEL: Record<string, string> = { admin: 'ผู้ดูแลระบบ', staff: 'พัสดุ', user: 'ผู้ใช้' }

const COLOR_OPTIONS = [
  'สีดำเมทัลลิก (Metallic Black)',
  'สีดำ (Black)',
  'สีขาว (White)',
  'สีเงิน (Silver)',
  'สีเทา (Gray)',
  'อื่น ๆ',
].map((value) => ({ value, label: value }))

const TEXT_STYLE_OPTIONS = [
  { value: 'normal', label: 'ปกติ (Normal Text)' },
  { value: 'heading', label: 'หัวข้อ (Heading)' },
]

interface BorrowFormValues {
  booker?: string
  phone?: string
  department?: string
  pickupDate?: Dayjs | null
  channel?: BorrowChannel
  equipmentId?: string
  quantity?: number
  color?: string
  category?: string
  subCategory?: string
  details?: string
  remark?: string
}

type DraftValues = Omit<BorrowFormValues, 'pickupDate'> & { pickupDate?: string | null; equipment?: Equipment | null }

function readDraft(): DraftValues | null {
  try {
    const raw = localStorage.getItem(DRAFT_KEY)
    return raw ? (JSON.parse(raw) as DraftValues) : null
  } catch {
    return null
  }
}

function clearDraft() {
  try {
    localStorage.removeItem(DRAFT_KEY)
  } catch {
    // ignore — storage ใช้ไม่ได้ก็ไม่เป็นไร
  }
}

/** หน้า "บันทึกรายการจองใหม่ (เพิ่มรายการ)" */
export function BorrowFormPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { message } = App.useApp()
  const user = useAuthStore((s) => s.user)
  const [form] = Form.useForm<BorrowFormValues>()
  const [draft] = useState(readDraft)
  const [picked, setPicked] = useState<Equipment | null>(draft?.equipment ?? null)
  const [equipmentSearch, setEquipmentSearch] = useState('')
  const [bookerSearch, setBookerSearch] = useState('')
  const [confirm, setConfirm] = useState<ConfirmVariant | null>(null)
  const [scanOpen, setScanOpen] = useState(false)
  const [scanCode, setScanCode] = useState('')
  const [now, setNow] = useState(() => dayjs())
  const detailsRef = useRef<TextAreaRef>(null)

  // นาฬิกาใน log อัปเดตทุก 30 วินาที
  useEffect(() => {
    const timer = window.setInterval(() => setNow(dayjs()), 30_000)
    return () => window.clearInterval(timer)
  }, [])

  const values = Form.useWatch([], form)
  const category = Form.useWatch('category', form)

  const initialValues = useMemo<BorrowFormValues>(
    () =>
      draft
        ? {
            ...draft,
            pickupDate: draft.pickupDate ? dayjs(draft.pickupDate) : null,
          }
        : { quantity: 1 },
    [draft],
  )

  const equipmentQuery = useQuery({
    queryKey: ['equipment', 'borrow-picker', equipmentSearch, category],
    queryFn: () =>
      equipmentApi.list({ search: equipmentSearch || undefined, category: category || undefined, limit: 20 }),
  })

  const categoriesQuery = useQuery({
    queryKey: ['equipment', 'categories'],
    queryFn: () => equipmentApi.categories(),
  })

  // รายชื่อผู้ยืมที่เคยมีรายการ — ใช้เป็นตัวช่วยเติมชื่อ (API ยังไม่มีค้นหาผู้ใช้)
  const bookersQuery = useQuery({
    queryKey: ['transactions', 'borrow', 'bookers', bookerSearch],
    queryFn: () => transactionsApi.list({ type: 'borrow', search: bookerSearch || undefined, limit: 50 }),
  })

  const bookerOptions = useMemo(
    () =>
      [...new Set((bookersQuery.data?.items ?? []).map((tx) => tx.userName))].map((name) => ({
        value: name,
        label: name,
      })),
    [bookersQuery.data],
  )

  const equipmentOptions = useMemo(() => {
    const items = equipmentQuery.data?.items ?? []
    const list = picked && !items.some((e) => e.id === picked.id) ? [picked, ...items] : items
    return list.map((e) => ({
      value: e.id,
      label: `${e.name} (${e.code})`,
      disabled: e.quantity - e.borrowedQuantity <= 0 && e.id !== picked?.id,
      equipment: e,
    }))
  }, [equipmentQuery.data, picked])

  const available = picked ? Math.max(picked.quantity - picked.borrowedQuantity, 0) : undefined

  const canSubmit = Boolean(
    values?.booker?.trim() &&
      values?.pickupDate &&
      values?.channel &&
      values?.equipmentId &&
      (values?.quantity ?? 0) >= 1 &&
      (available === undefined || (values?.quantity ?? 0) <= available),
  )

  const create = useMutation({
    mutationFn: (v: BorrowFormValues) => {
      const channel = BORROW_CHANNELS.find((c) => c.value === v.channel)
      return transactionsApi.create({
        type: 'borrow',
        equipmentId: v.equipmentId!,
        quantity: v.quantity ?? 1,
        note: buildBorrowNote({
          booker: v.booker,
          phone: v.phone,
          department: v.department,
          pickupDate: v.pickupDate?.format('DD/MM/YYYY'),
          channel: channel?.short,
          color: v.color,
          category: v.category,
          subCategory: v.subCategory,
          details: v.details,
          remark: v.remark,
        }),
      })
    },
    onSuccess: () => {
      clearDraft()
      void queryClient.invalidateQueries({ queryKey: ['transactions'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      void queryClient.invalidateQueries({ queryKey: ['equipment'] })
      message.success('บันทึกรายการจองแล้ว')
      navigate('/borrow')
    },
    onError: (error) => {
      setConfirm(null)
      message.error(getErrorMessage(error, 'บันทึกรายการจองไม่สำเร็จ'))
    },
  })

  const pickEquipment = (equipment: Equipment | null) => {
    setPicked(equipment)
    form.setFieldsValue({
      equipmentId: equipment?.id,
      category: equipment?.category ?? form.getFieldValue('category'),
    })
  }

  const saveDraft = () => {
    const v = form.getFieldsValue(true) as BorrowFormValues
    try {
      localStorage.setItem(
        DRAFT_KEY,
        JSON.stringify({ ...v, pickupDate: v.pickupDate?.toISOString() ?? null, equipment: picked }),
      )
      message.success('บันทึกฉบับร่างแล้ว')
    } catch {
      message.error('บันทึกฉบับร่างไม่สำเร็จ')
    }
    setConfirm(null)
  }

  const scan = async () => {
    const code = scanCode.trim()
    if (!code) return
    try {
      const res = await equipmentApi.list({ search: code, limit: 20 })
      const hit = res.items.find((e) => e.code.toLowerCase() === code.toLowerCase()) ?? res.items[0]
      if (!hit) {
        message.warning('ไม่พบครุภัณฑ์จากรหัสนี้')
        return
      }
      pickEquipment(hit)
      setScanOpen(false)
      setScanCode('')
    } catch (error) {
      message.error(getErrorMessage(error, 'ค้นหาครุภัณฑ์ไม่สำเร็จ'))
    }
  }

  /** ปุ่มจัดรูปแบบ — ครอบข้อความที่เลือกด้วยสัญลักษณ์แบบ markdown */
  const format = (before: string, after = before) => {
    const el = detailsRef.current?.resizableTextArea?.textArea
    const text: string = form.getFieldValue('details') ?? ''
    const start = el?.selectionStart ?? text.length
    const end = el?.selectionEnd ?? text.length
    form.setFieldValue('details', text.slice(0, start) + before + text.slice(start, end) + after + text.slice(end))
    el?.focus()
  }

  const quantity = values?.quantity ?? 0
  const stepQuantity = (delta: number) => {
    const next = Math.max(1, Math.min(quantity + delta, available ?? Infinity))
    form.setFieldValue('quantity', next)
  }

  const confirmCopy: Record<ConfirmVariant, { title: string; description: string; okText: string }> = {
    confirm: {
      title: 'ยืนยันการบันทึกข้อมูล ?',
      description: 'โปรดตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยัน',
      okText: 'ยืนยัน',
    },
    draft: {
      title: 'ต้องการบันทึกเป็นฉบับร่างใช่ไหม?',
      description: 'ข้อมูลที่กรอกไว้จะถูกบันทึก และคุณสามารถกลับมาแก้ไขได้ภายหลัง',
      okText: 'ยืนยัน',
    },
    danger: {
      title: 'ต้องการยกเลิกรายการบันทึก?',
      description: 'ข้อมูลที่กรอกไว้ (รวมถึงฉบับร่าง) จะถูกลบ และไม่สามารถกู้คืนได้',
      okText: 'ลบ',
    },
  }

  const onConfirm = () => {
    if (confirm === 'confirm') create.mutate(form.getFieldsValue(true) as BorrowFormValues)
    else if (confirm === 'draft') saveDraft()
    else if (confirm === 'danger') {
      clearDraft()
      setConfirm(null)
      navigate('/borrow')
    }
  }

  return (
    <div className="page borrow-form-page" data-testid="borrow-form-page">
      <PageHeader
        size="lg"
        title="บันทึกรายการจองใหม่ (เพิ่มรายการ)"
        subtitle="ระบบจองและลงทะเบียนครุภัณฑ์สำหรับเจ้าหน้าที่ (RP.Rent Backend)"
        actions={
          <Button className="borrow-back" data-testid="borrow-form-back" onClick={() => navigate('/borrow')}>
            ย้อนกลับ
          </Button>
        }
      />

      <div className="borrow-form__layout">
        <Form<BorrowFormValues>
          form={form}
          layout="vertical"
          requiredMark={false}
          initialValues={initialValues}
          className="borrow-form"
          data-testid="borrow-form"
          onFinish={() => setConfirm('confirm')}
        >
          {/* 1. ผู้จอง */}
          <FormSection icon={<UserOutlined />} title="1. ข้อมูลผู้จองครุภัณฑ์">
            <Form.Item label="ค้นหาผู้จอง (เลขบัตรประชาชน / ชื่อ)" name="booker">
              <AutoComplete
                options={bookerOptions}
                onSearch={setBookerSearch}
                data-testid="borrow-booker"
              >
                <Input prefix={<UserOutlined />} placeholder="กรอกชื่อ-นามสกุล หรือ รหัสประจำตัว เช่น สมชาย รักดี" />
              </AutoComplete>
            </Form.Item>
            <div className="borrow-form__grid">
              <Form.Item label="เบอร์โทรศัพท์ผู้ติดต่อ" name="phone">
                <Input placeholder="เช่น 089-123-4567" inputMode="tel" data-testid="borrow-phone" />
              </Form.Item>
              <Form.Item label="หน่วยงาน / ภาควิชา" name="department">
                <Input placeholder="ระบุสังกัด เช่น ฝ่ายเทคโนโลยีสารสนเทศ" data-testid="borrow-department" />
              </Form.Item>
            </div>
          </FormSection>

          <hr className="borrow-form__divider" />

          {/* 2. วันเวลา / ช่องทาง */}
          <FormSection icon={<CalendarOutlined />} title="2. ข้อมูลวันเวลาและประเภทการจอง">
            <Form.Item label="วันที่รับครุภัณฑ์" name="pickupDate">
              <DatePicker
                className="borrow-form__date"
                format="DD/MM/YYYY"
                placeholder="วว/ดด/ปปปป"
                suffixIcon={<CalendarOutlined />}
                data-testid="borrow-date"
              />
            </Form.Item>
            <Form.Item label="ประเภทช่องทางการจอง" name="channel">
              <Select
                className="borrow-form__select"
                prefix={<UserOutlined />}
                suffixIcon={<DownOutlined />}
                placeholder="เลือกประเภท เช่น Walk-in (ติดต่อหน้าเคาน์เตอร์)"
                options={BORROW_CHANNELS.map(({ value, label }) => ({ value, label }))}
                data-testid="borrow-channel"
              />
            </Form.Item>
          </FormSection>

          <hr className="borrow-form__divider" />

          {/* 3. ครุภัณฑ์ */}
          <FormSection icon={<FolderAddOutlined />} title="3. รายการครุภัณฑ์ที่ต้องการจอง">
            <div className="borrow-form__scan">
              <span className="borrow-form__scan-label">
                <ScanOutlined /> สแกนบาร์โค้ดครุภัณฑ์
              </span>
              <Button
                type="primary"
                className="borrow-form__scan-btn"
                data-testid="borrow-scan"
                onClick={() => setScanOpen(true)}
              >
                สแกน QR / บาร์โค้ด
              </Button>
            </div>
            <p className="borrow-form__hint">
              <ExclamationCircleOutlined /> หากสแกนไม่ได้ สามารถค้นหาหรือกรอกเองได้ตามปกติ
            </p>
            <hr className="borrow-form__divider is-tight" />

            <Form.Item label="ค้นหาและเลือกครุภัณฑ์ในคลัง" name="equipmentId">
              <Select
                showSearch={{ filterOption: false, onSearch: setEquipmentSearch }}
                className="borrow-form__search"
                prefix={<UserOutlined />}
                suffixIcon={null}
                allowClear
                placeholder="พิมพ์ค้นหารหัสครุภัณฑ์ หรือชื่อครุภัณฑ์ เช่น กล้องถ่ายภาพ DSLR..."
                loading={equipmentQuery.isFetching}
                options={equipmentOptions}
                notFoundContent={equipmentQuery.isFetching ? 'กำลังค้นหา...' : 'ไม่พบครุภัณฑ์'}
                onChange={(_, option) => {
                  const hit = Array.isArray(option) ? undefined : option
                  pickEquipment((hit as { equipment?: Equipment } | undefined)?.equipment ?? null)
                }}
                data-testid="borrow-equipment"
              />
            </Form.Item>

            <div className="borrow-form__grid">
              <Form.Item label="ชื่อครุภัณฑ์">
                <Input value={picked?.name} readOnly placeholder="กล้องถ่ายภาพนิ่งและภาพเคลื่อนไหว DSLR" data-testid="borrow-equipment-name" />
              </Form.Item>
              <Form.Item label="รหัสครุภัณฑ์">
                <Input value={picked?.code} readOnly placeholder="คร.65-0123-998" data-testid="borrow-equipment-code" />
              </Form.Item>

              <Form.Item
                label="จำนวน"
                extra={available !== undefined ? `คงเหลือพร้อมยืม ${available} ${picked?.unit ?? ''}` : undefined}
              >
                <div className="borrow-qty">
                  <FolderOutlined className="borrow-qty__icon" />
                  <Form.Item name="quantity" noStyle>
                    <InputNumber
                      variant="borderless"
                      controls={false}
                      min={1}
                      max={available || undefined}
                      precision={0}
                      placeholder="เลือกหรือกรอกจำนวน"
                      className="borrow-qty__input"
                      data-testid="borrow-quantity"
                    />
                  </Form.Item>
                  <div className="borrow-qty__stepper">
                    <button type="button" aria-label="ลดจำนวน" onClick={() => stepQuantity(-1)}>
                      <MinusOutlined />
                    </button>
                    <span>{quantity}</span>
                    <button type="button" aria-label="เพิ่มจำนวน" onClick={() => stepQuantity(1)}>
                      <PlusOutlined />
                    </button>
                  </div>
                </div>
              </Form.Item>
              <Form.Item label="สี" name="color">
                <Select
                  className="borrow-form__select"
                  prefix={<BgColorsOutlined />}
                  suffixIcon={<DownOutlined />}
                  allowClear
                  placeholder="เลือกสี"
                  options={COLOR_OPTIONS}
                  data-testid="borrow-color"
                />
              </Form.Item>

              <Form.Item label="หมวดหมู่หลัก" name="category">
                <Select
                  className="borrow-form__select"
                  prefix={<TagOutlined />}
                  suffixIcon={<DownOutlined />}
                  allowClear
                  placeholder="อุปกรณ์สตูดิโอและมีเดีย"
                  options={(categoriesQuery.data ?? []).map((c) => ({ value: c, label: c }))}
                  data-testid="borrow-category"
                />
              </Form.Item>
              <Form.Item label="หมวดหมู่ย่อย" name="subCategory">
                <AutoComplete
                  className="borrow-form__select"
                  options={equipmentOptions.map((o) => ({ value: o.equipment.name }))}
                  filterOption={(input, option) =>
                    String(option?.value ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                >
                  <Input prefix={<TagOutlined />} suffix={<DownOutlined />} placeholder="กล้องถ่ายภาพนิ่ง" data-testid="borrow-subcategory" />
                </AutoComplete>
              </Form.Item>
            </div>

            <Form.Item label="รายละเอียดเพิ่มเติม / สภาพพัสดุก่อนรับ" className="borrow-editor-item">
              <div className="borrow-editor">
                <div className="borrow-editor__toolbar">
                  <Select
                    variant="borderless"
                    size="small"
                    defaultValue="normal"
                    options={TEXT_STYLE_OPTIONS}
                    popupMatchSelectWidth={false}
                    className="borrow-editor__style"
                    suffixIcon={<DownOutlined />}
                    onChange={(v) => v === 'heading' && format('# ', '')}
                  />
                  <i className="borrow-editor__sep" />
                  <button type="button" aria-label="ตัวหนา" onClick={() => format('**')}>
                    <FontSizeOutlined />
                  </button>
                  <button type="button" aria-label="ตัวเอียง" onClick={() => format('_')}>
                    <ItalicOutlined />
                  </button>
                  <button type="button" aria-label="ขีดเส้นใต้" onClick={() => format('__')}>
                    <UnderlineOutlined />
                  </button>
                  <i className="borrow-editor__sep" />
                  <button type="button" aria-label="ลิงก์" onClick={() => format('[', '](https://)')}>
                    <LinkOutlined />
                  </button>
                  <button type="button" aria-label="รายการ" onClick={() => format('\n- ', '')}>
                    <UnorderedListOutlined />
                  </button>
                </div>
                <Form.Item name="details" noStyle>
                  <Input.TextArea
                    ref={detailsRef}
                    variant="borderless"
                    autoSize={{ minRows: 4, maxRows: 12 }}
                    placeholder="กรอกข้อมูล"
                    className="borrow-editor__area"
                    data-testid="borrow-details"
                  />
                </Form.Item>
              </div>
            </Form.Item>
          </FormSection>

          <hr className="borrow-form__divider" />

          {/* 4. หมายเหตุ */}
          <section className="borrow-form__section">
            <h2 className="borrow-form__title is-plain">4. หมายเหตุเพิ่มเติม</h2>
            <Form.Item name="remark" className="borrow-form__remark">
              <Input
                placeholder="ระบุรายละเอียดอื่นๆ เช่น มอบอำนาจให้บุคคลอื่นรับแทน หรือ ระบุรหัสโปรเจกต์กิจกรรมที่ใช้พัสดุ"
                data-testid="borrow-remark"
              />
            </Form.Item>
          </section>
        </Form>

        {/* 5. สรุป log */}
        <aside className="borrow-summary" data-testid="borrow-summary">
          <h2 className="borrow-summary__title">5. สรุปบันทึกการทำงาน (Log)</h2>
          <dl className="borrow-summary__meta">
            <div>
              <dt>ผู้ดำเนินการบันทึก:</dt>
              <dd>{user ? `${user.name} (${ROLE_LABEL[user.role] ?? user.role})` : '-'}</dd>
            </div>
            <div>
              <dt>วันเวลาที่ลงบันทึก:</dt>
              <dd>{formatThaiDateTime(now)}</dd>
            </div>
          </dl>
          <hr className="borrow-summary__line" />
          <div className="borrow-summary__terms">
            <h3>ข้อตกลงและเงื่อนไข</h3>
            <p>
              * พัสดุต้องถูกส่งมอบคืนในสภาพสมบูรณ์เหมือนเมื่อรับไป
              หากชำรุดเสียหายผู้ยืมต้องรับผิดชอบค่าใช้จ่ายในการซ่อมบำรุงตามจริง
            </p>
          </div>
          <hr className="borrow-summary__line" />
          <div className="borrow-summary__actions">
            <Button
              type="primary"
              className="borrow-summary__submit"
              disabled={!canSubmit}
              onClick={() => form.submit()}
              data-testid="borrow-submit"
            >
              บันทึกรายการจอง
            </Button>
            <div className="borrow-summary__row">
              <Button className="borrow-summary__draft" onClick={() => setConfirm('draft')} data-testid="borrow-draft">
                บันทึกฉบับร่าง
              </Button>
              <Button className="borrow-summary__cancel" onClick={() => setConfirm('danger')} data-testid="borrow-cancel">
                ยกเลิก
              </Button>
            </div>
          </div>
        </aside>
      </div>

      <ConfirmModal
        open={confirm !== null}
        variant={confirm ?? 'confirm'}
        title={confirm ? confirmCopy[confirm].title : ''}
        description={confirm ? confirmCopy[confirm].description : undefined}
        okText={confirm ? confirmCopy[confirm].okText : undefined}
        loading={create.isPending}
        onOk={onConfirm}
        onCancel={() => setConfirm(null)}
        testId="borrow-confirm"
      />

      <Modal
        open={scanOpen}
        title="สแกน QR / บาร์โค้ด"
        okText="ค้นหา"
        cancelText="ยกเลิก"
        width={420}
        centered
        destroyOnHidden
        onOk={() => void scan()}
        onCancel={() => setScanOpen(false)}
      >
        <p className="borrow-scan__hint">ใช้เครื่องสแกนยิงบาร์โค้ด หรือพิมพ์รหัสครุภัณฑ์แล้วกด Enter</p>
        <Input
          autoFocus
          prefix={<ScanOutlined />}
          value={scanCode}
          placeholder="รหัสครุภัณฑ์"
          onChange={(e) => setScanCode(e.target.value)}
          onPressEnter={() => void scan()}
          data-testid="borrow-scan-input"
        />
      </Modal>
    </div>
  )
}

/** หัวข้อย่อยของฟอร์ม: ไอคอน + ชื่อหัวข้อ + ฟิลด์ */
function FormSection({ icon, title, children }: { icon: ReactNode; title: string; children: ReactNode }) {
  return (
    <section className="borrow-form__section">
      <h2 className="borrow-form__title">
        <span className="borrow-form__icon">{icon}</span>
        {title}
      </h2>
      {children}
    </section>
  )
}
