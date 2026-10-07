import '../equipment.css'
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  App,
  AutoComplete,
  Button,
  DatePicker,
  Form,
  Input,
  InputNumber,
  Progress,
  Select,
  Upload,
} from 'antd'
import {
  AlignLeftOutlined,
  BgColorsOutlined,
  BoldOutlined,
  CloseCircleOutlined,
  DownOutlined,
  EyeOutlined,
  FolderAddOutlined,
  ItalicOutlined,
  LinkOutlined,
  MinusOutlined,
  PlusOutlined,
  TagOutlined,
  UnderlineOutlined,
  UnorderedListOutlined,
  UploadOutlined,
} from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import dayjs, { type Dayjs } from 'dayjs'
import { getErrorMessage } from '@/shared/api/http'
import { formatCurrency, formatNumber } from '@/shared/utils/format'
import { PageHeader } from '@/shared/components/page-header'
import { StatusPill } from '@/shared/components/status-pill'
import { ConfirmModal } from '@/shared/components/confirm-modal'
import { equipmentApi } from '../api/equipment.api'
import {
  EQUIPMENT_STATUS_LABEL,
  type EquipmentInput,
  type EquipmentStatus,
} from '../types/equipment.types'

interface FormValues {
  name: string
  code: string
  category: string
  /** UI เท่านั้น — API ไม่มีฟิลด์นี้ จะต่อท้ายลงใน description ตอนบันทึก */
  subCategory?: string
  /** UI เท่านั้น — เหมือน subCategory */
  color?: string
  department: string
  price: number
  quantity: number
  unit: string
  status: EquipmentStatus
  purchasedAt?: Dayjs
  description?: string
}

/** รูปที่แนบ — ไฟล์จากเครื่อง (object URL สำหรับพรีวิว) หรือลิงก์ภายนอก */
interface MediaItem {
  uid: string
  name: string
  url: string
  size?: number
  isLink?: boolean
}

type ModalKind = 'confirm' | 'draft' | 'cancel'

const STEPS = [
  { key: 'info', label: 'ข้อมูลครุภัณฑ์' },
  { key: 'media', label: 'อัปโหลดรูปภาพ' },
  { key: 'review', label: 'ตรวจสอบและบันทึก' },
]

/** ฟิลด์ที่ต้องกรอกในแต่ละขั้น — ใช้ validate ก่อนกด "ถัดไป" และคำนวณ % ความครบถ้วน */
const REQUIRED_FIELDS: (keyof FormValues)[] = ['name', 'code', 'category', 'quantity', 'price']

const DESCRIPTION_MAX = 500

const STATUS_TONE = {
  ready: 'green',
  borrowed: 'blue',
  maintenance: 'orange',
  retired: 'gray',
} as const

const formatSize = (bytes?: number) => {
  if (bytes === undefined) return 'ลิงก์ภายนอก'
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

/** ต่อ สี/หมวดหมู่ย่อย ท้าย description เพราะ API ยังไม่มีฟิลด์รองรับ */
const composeDescription = (raw: FormValues) => {
  const extras = [
    raw.color?.trim() && `สี: ${raw.color.trim()}`,
    raw.subCategory?.trim() && `หมวดหมู่ย่อย: ${raw.subCategory.trim()}`,
  ]
    .filter(Boolean)
    .join(' · ')
  return [raw.description?.trim(), extras].filter(Boolean).join('\n\n') || undefined
}

/** ไอคอนโฟลเดอร์ + ลูกศรขึ้น ในกล่องลากวางไฟล์ */
function UploadFolderIcon() {
  return (
    <svg width="44" height="44" viewBox="0 0 44 44" fill="none" aria-hidden>
      <path d="M2 8a4 4 0 0 1 4-4h11l4 5h17a4 4 0 0 1 4 4v23a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8Z" fill="#1849d6" />
      <path d="M2 14a4 4 0 0 1 4-4h32a4 4 0 0 1 4 4v22a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V14Z" fill="#2f63f0" />
      <circle cx="22" cy="26" r="8" fill="#fff" />
      <path d="M22 30.5v-9M18.5 25l3.5-3.5 3.5 3.5" stroke="#1849d6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

/**
 * หน้าเพิ่มครุภัณฑ์ — wizard 3 ขั้น
 * selector สำหรับ Robot: data-testid = wizard-step-{n} / field-{name} / wizard-next /
 *                                     wizard-back / wizard-submit / wizard-draft / wizard-cancel /
 *                                     wizard-progress / wizard-confirm(-ok|-cancel)
 */
export function EquipmentFormPage() {
  const [form] = Form.useForm<FormValues>()
  const [step, setStep] = useState(0)
  const [files, setFiles] = useState<MediaItem[]>([])
  const [linkDraft, setLinkDraft] = useState('')
  const [modal, setModal] = useState<ModalKind | null>(null)
  const values = Form.useWatch([], form)
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { message } = App.useApp()

  // เก็บ object URL ล่าสุดไว้ revoke ตอนออกจากหน้า
  const filesRef = useRef(files)
  useEffect(() => {
    filesRef.current = files
  }, [files])
  useEffect(
    () => () => filesRef.current.forEach((f) => !f.isLink && URL.revokeObjectURL(f.url)),
    [],
  )

  const { data: categories = [] } = useQuery({
    queryKey: ['equipment', 'categories'],
    queryFn: () => equipmentApi.categories(),
  })

  // หมวดหมู่ย่อยไม่มีใน API — แนะนำจากชื่อครุภัณฑ์ที่มีอยู่แล้วในหมวดเดียวกัน
  const category = values?.category
  const { data: sameCategory } = useQuery({
    queryKey: ['equipment', 'list', { category, limit: 100 }],
    queryFn: () => equipmentApi.list({ category, limit: 100 }),
    enabled: Boolean(category),
  })
  const subCategoryOptions = useMemo(
    () =>
      [...new Set((sameCategory?.items ?? []).map((item) => item.name))].map((name) => ({
        value: name,
      })),
    [sameCategory],
  )

  const completion = useMemo(() => {
    if (!values) return 0
    const filled = REQUIRED_FIELDS.filter((key) => {
      const value = values[key]
      return value !== undefined && value !== null && value !== ''
    }).length
    const base = Math.round((filled / REQUIRED_FIELDS.length) * 80)
    return Math.min(100, base + (files.length > 0 ? 20 : 0))
  }, [values, files.length])

  const save = useMutation({
    mutationFn: (input: EquipmentInput) => equipmentApi.create(input),
    onSuccess: (created) => {
      void queryClient.invalidateQueries({ queryKey: ['equipment'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      message.success(
        created.isDraft ? 'บันทึกฉบับร่างแล้ว' : `เพิ่มครุภัณฑ์ ${created.name} เรียบร้อย`,
      )
      navigate('/reports')
    },
    onError: (error) => message.error(getErrorMessage(error, 'บันทึกไม่สำเร็จ')),
    onSettled: () => setModal(null),
  })

  const toInput = (raw: FormValues, isDraft: boolean): EquipmentInput => ({
    name: raw.name,
    code: raw.code,
    category: raw.category,
    department: raw.department,
    price: raw.price,
    quantity: raw.quantity,
    unit: raw.unit,
    status: raw.status,
    description: composeDescription(raw),
    purchasedAt: raw.purchasedAt ? raw.purchasedAt.toISOString() : undefined,
    images: files.map((file) => (file.isLink ? file.url : file.name)),
    isDraft,
  })

  const next = async () => {
    if (step === 0) await form.validateFields(REQUIRED_FIELDS)
    setStep((s) => Math.min(STEPS.length - 1, s + 1))
  }

  // ขั้นสุดท้าย: validate ทั้งฟอร์มก่อนเปิด modal ยืนยัน — ถ้าไม่ผ่านพากลับไปขั้นแรกให้เห็น error
  const askSubmit = async () => {
    try {
      await form.validateFields()
      setModal('confirm')
    } catch {
      setStep(0)
    }
  }

  const submit = async () => {
    const raw = await form.validateFields()
    save.mutate(toInput(raw, false))
  }

  const askDraft = () => {
    const raw = form.getFieldsValue()
    if (!raw.name || !raw.code || !raw.category) {
      message.warning('กรอกชื่อ รหัส และหมวดหมู่ก่อนบันทึกฉบับร่าง')
      return
    }
    setModal('draft')
  }

  const saveDraft = () => {
    const raw = form.getFieldsValue()
    save.mutate(toInput({ ...raw, price: raw.price ?? 0, quantity: raw.quantity ?? 1 }, true))
  }

  const discard = () => {
    setModal(null)
    navigate('/reports')
  }

  const stepQuantity = (delta: number) => {
    const current = Number(form.getFieldValue('quantity')) || 0
    form.setFieldValue('quantity', Math.max(1, current + delta))
    void form.validateFields(['quantity']).catch(() => undefined)
  }

  const addFile = (file: File) => {
    setFiles((list) => [
      ...list,
      {
        uid: `${file.name}-${Date.now()}`,
        name: file.name,
        size: file.size,
        url: URL.createObjectURL(file),
      },
    ])
    return false // ยังไม่มี endpoint อัปโหลดจริง — เก็บแค่ชื่อไฟล์
  }

  const addLink = () => {
    const link = linkDraft.trim()
    if (!link) return
    if (!/^https?:\/\//i.test(link)) {
      message.warning('ลิงก์ต้องขึ้นต้นด้วย http:// หรือ https://')
      return
    }
    const name = decodeURIComponent(link.split('/').pop()?.split('?')[0] || link)
    setFiles((list) => [...list, { uid: `link-${Date.now()}`, name, url: link, isLink: true }])
    setLinkDraft('')
  }

  const removeFile = (item: MediaItem) => {
    if (!item.isLink) URL.revokeObjectURL(item.url)
    setFiles((list) => list.filter((f) => f.uid !== item.uid))
  }

  const empty = <span className="eq-review__empty">-</span>
  const isLast = step === STEPS.length - 1

  return (
    <div className="page eq-wizard" data-testid="equipment-form-page">
      <PageHeader
        size="lg"
        title="ข้อมูลครุภัณฑ์"
        subtitle="กรุณาตรวจสอบรายละเอียดความถูกต้องของครุภัณฑ์ก่อนกดบันทึกเข้าสู่ระบบ"
      />

      <div className="eq-wizard__body">
        <nav className="eq-steps" data-testid="wizard-steps">
          <h2 className="eq-steps__title">ขั้นตอนการทำงาน</h2>
          <ol className="eq-steps__list">
            {STEPS.map((item, index) => (
              <li key={item.key}>
                <button
                  type="button"
                  data-testid={`wizard-step-${index + 1}`}
                  className={`eq-steps__item${index === step ? ' is-active' : index < step ? ' is-done' : ''}`}
                  aria-current={index === step ? 'step' : undefined}
                  onClick={() => index < step && setStep(index)}
                >
                  {index + 1}. {item.label}
                </button>
              </li>
            ))}
          </ol>
        </nav>

        <section className={`eq-panel eq-panel--${STEPS[step].key}`}>
          <Form<FormValues>
            form={form}
            layout="vertical"
            requiredMark={false}
            className="eq-form"
            initialValues={{ status: 'ready', unit: 'ชิ้น', department: '' }}
          >
            {/* ── ขั้น 1: ข้อมูลครุภัณฑ์ ── */}
            <div hidden={step !== 0} data-testid="wizard-panel-info" className="eq-step">
              <h2 className="eq-panel__title">Product Information</h2>

              <div className="eq-form__grid">
                <Form.Item
                  label="ชื่อครุภัณฑ์"
                  name="name"
                  rules={[{ required: true, message: 'กรุณากรอกชื่อครุภัณฑ์' }]}
                >
                  <Input data-testid="field-name" placeholder="กรอกข้อมูล" className="eq-input" />
                </Form.Item>
                <Form.Item
                  label="รหัสครุภัณฑ์"
                  name="code"
                  rules={[{ required: true, message: 'กรุณากรอกรหัสครุภัณฑ์' }]}
                >
                  <Input data-testid="field-code" placeholder="กรอกข้อมูล" className="eq-input" />
                </Form.Item>

                {/* จำนวน: ช่องพิมพ์ + ปุ่ม −/+ อยู่ในกรอบเดียวกัน */}
                <Form.Item label="จำนวน" required>
                  <div className="eq-qty">
                    <FolderAddOutlined className="eq-field-icon" />
                    <Form.Item
                      name="quantity"
                      noStyle
                      rules={[{ required: true, message: 'กรุณากรอกจำนวน' }]}
                    >
                      <InputNumber
                        data-testid="field-quantity"
                        min={1}
                        precision={0}
                        controls={false}
                        variant="borderless"
                        placeholder="เลือกหรือกรอกจำนวน"
                        className="eq-qty__input"
                      />
                    </Form.Item>
                    <div className="eq-qty__stepper">
                      <button
                        type="button"
                        aria-label="ลดจำนวน"
                        data-testid="field-quantity-minus"
                        onClick={() => stepQuantity(-1)}
                      >
                        <MinusOutlined />
                      </button>
                      <span className="eq-qty__value">{values?.quantity ?? 0}</span>
                      <button
                        type="button"
                        aria-label="เพิ่มจำนวน"
                        data-testid="field-quantity-plus"
                        onClick={() => stepQuantity(1)}
                      >
                        <PlusOutlined />
                      </button>
                    </div>
                  </div>
                </Form.Item>
                <Form.Item label="สี" name="color">
                  <Input
                    data-testid="field-color"
                    placeholder="กรอกข้อมูล"
                    className="eq-input eq-input--44"
                    prefix={<BgColorsOutlined className="eq-field-icon" />}
                  />
                </Form.Item>

                <Form.Item
                  label="หมวดหมู่"
                  name="category"
                  rules={[{ required: true, message: 'กรุณาเลือกหมวดหมู่' }]}
                >
                  <Select
                    data-testid="field-category"
                    placeholder="กรอกข้อมูล"
                    showSearch
                    className="eq-select"
                    prefix={<TagOutlined className="eq-field-icon" />}
                    suffixIcon={<DownOutlined className="eq-chevron" />}
                    options={categories.map((c) => ({ value: c, label: c }))}
                  />
                </Form.Item>
                <Form.Item label="หมวดหมู่ย่อย" name="subCategory">
                  <AutoComplete
                    data-testid="field-sub-category"
                    placeholder="กรอกข้อมูล"
                    className="eq-select"
                    prefix={<TagOutlined className="eq-field-icon" />}
                    suffixIcon={<DownOutlined className="eq-chevron" />}
                    options={subCategoryOptions}
                    showSearch={{
                      filterOption: (input, option) =>
                        String(option?.value ?? '').toLowerCase().includes(input.toLowerCase()),
                    }}
                  />
                </Form.Item>

                {/* ฟิลด์ที่ API ต้องใช้แต่ดีไซน์ไม่มี — จัดให้อยู่ใน grid เดียวกัน */}
                <Form.Item label="หน่วยงานผู้รับผิดชอบ" name="department">
                  <Input
                    data-testid="field-department"
                    placeholder="เช่น ฝ่ายบริหารทั่วไป"
                    className="eq-input"
                  />
                </Form.Item>
                <Form.Item
                  label="ราคาต่อหน่วย (บาท)"
                  name="price"
                  rules={[{ required: true, message: 'กรุณากรอกราคา' }]}
                >
                  <InputNumber
                    data-testid="field-price"
                    min={0}
                    controls={false}
                    placeholder="0.00"
                    className="eq-number"
                  />
                </Form.Item>

                <div className="eq-form__pair">
                  <Form.Item label="หน่วยนับ" name="unit">
                    <Input data-testid="field-unit" placeholder="ชิ้น" className="eq-input" />
                  </Form.Item>
                  <Form.Item label="สถานะ" name="status">
                    <Select
                      data-testid="field-status"
                      className="eq-select eq-select--40"
                      suffixIcon={<DownOutlined className="eq-chevron" />}
                      options={Object.entries(EQUIPMENT_STATUS_LABEL).map(([value, label]) => ({
                        value,
                        label,
                      }))}
                    />
                  </Form.Item>
                </div>
                <Form.Item label="วันที่จัดซื้อ" name="purchasedAt">
                  <DatePicker
                    data-testid="field-purchased-at"
                    className="eq-number"
                    format="DD/MM/YYYY"
                    placeholder="เลือกวันที่"
                  />
                </Form.Item>
              </div>

              <Form.Item label="รายละเอียด" className="eq-form__desc">
                <div className="eq-editor">
                  {/* แถบเครื่องมือตามดีไซน์ — ช่องนี้เก็บเป็นข้อความธรรมดา จึงเป็นแค่การตกแต่ง */}
                  <div className="eq-editor__toolbar" aria-hidden>
                    <span className="eq-editor__style">
                      Heading <DownOutlined />
                    </span>
                    <i className="eq-editor__sep" />
                    <BoldOutlined />
                    <ItalicOutlined />
                    <UnderlineOutlined />
                    <i className="eq-editor__sep" />
                    <LinkOutlined />
                    <UnorderedListOutlined />
                    <AlignLeftOutlined />
                  </div>
                  <Form.Item name="description" noStyle>
                    <Input.TextArea
                      data-testid="field-description"
                      placeholder="กรอกข้อมูล"
                      variant="borderless"
                      maxLength={DESCRIPTION_MAX}
                      className="eq-editor__body"
                    />
                  </Form.Item>
                </div>
              </Form.Item>
              <p className="eq-editor__count">
                {values?.description?.length
                  ? `${values.description.length}/${DESCRIPTION_MAX}`
                  : `Max ${DESCRIPTION_MAX}`}
              </p>
            </div>

            {/* ── ขั้น 2: อัปโหลดรูปภาพ ── */}
            <div hidden={step !== 1} data-testid="wizard-panel-media" className="eq-step">
              <h2 className="eq-panel__title eq-panel__title--thai">อัปโหลดรูปภาพ</h2>

              <div className="eq-upload">
                <span className="eq-upload__label">Photo</span>
                <Upload.Dragger
                  data-testid="field-upload"
                  className="eq-dropzone"
                  multiple
                  beforeUpload={addFile}
                  showUploadList={false}
                  accept=".jpg,.jpeg,.png,.svg,.webp"
                >
                  <UploadFolderIcon />
                  <p className="eq-dropzone__text">Drag your file(s) to start uploading</p>
                  <p className="eq-dropzone__or">
                    <span>OR</span>
                  </p>
                  <span className="eq-dropzone__browse">Browse files</span>
                </Upload.Dragger>
              </div>
              <p className="eq-upload__hint">Only support .jpg, .png, .svg and .webp files</p>

              <div className="eq-divider">
                <span>ไฟล์ที่อัปโหลด</span>
              </div>

              {files.length > 0 && (
                <ul className="eq-files" data-testid="uploaded-files">
                  {files.map((file) => (
                    <li key={file.uid} className="eq-file">
                      <div className="eq-file__meta">
                        <strong>{file.name}</strong>
                        <small>{formatSize(file.size)}</small>
                      </div>
                      <span className="eq-file__actions">
                        <button
                          type="button"
                          className="eq-file__btn is-view"
                          aria-label={`ดู ${file.name}`}
                          onClick={() => window.open(file.url, '_blank', 'noopener')}
                        >
                          <EyeOutlined />
                        </button>
                        <button
                          type="button"
                          className="eq-file__btn is-remove"
                          aria-label={`ลบ ${file.name}`}
                          data-testid="remove-file"
                          onClick={() => removeFile(file)}
                        >
                          <CloseCircleOutlined />
                        </button>
                      </span>
                    </li>
                  ))}
                </ul>
              )}

              <div className="eq-link">
                <label htmlFor="eq-link-input" className="eq-upload__label">
                  เพิ่มลิงค์
                </label>
                <Input
                  id="eq-link-input"
                  data-testid="field-link"
                  className="eq-input eq-input--48"
                  placeholder="กรอกลิงก์รูปภาพ แล้วกด Enter"
                  prefix={<LinkOutlined className="eq-field-icon" />}
                  value={linkDraft}
                  onChange={(e) => setLinkDraft(e.target.value)}
                  onPressEnter={(e) => {
                    e.preventDefault()
                    addLink()
                  }}
                />
              </div>
            </div>

            {/* ── ขั้น 3: ตรวจสอบและบันทึก ── */}
            <div hidden={step !== 2} data-testid="wizard-panel-review" className="eq-step eq-review">
              <div className="eq-review__group">
                <header className="eq-review__head">
                  <h2 className="eq-panel__title">รายละเอียดครุภัณฑ์</h2>
                  <button
                    type="button"
                    className="eq-chip"
                    data-testid="review-edit-info"
                    onClick={() => setStep(0)}
                  >
                    แก้ไข
                  </button>
                </header>

                <dl className="eq-review__grid">
                  <div className="eq-review__item">
                    <dt>ชื่อครุภัณฑ์</dt>
                    <dd data-testid="review-name">{values?.name || empty}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>รหัสครุภัณฑ์</dt>
                    <dd data-testid="review-code">{values?.code || empty}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>หมวดหมู่</dt>
                    <dd data-testid="review-category">{values?.category || empty}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>หมวดหมู่ย่อย</dt>
                    <dd data-testid="review-sub-category">{values?.subCategory || empty}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>จำนวนในระบบ</dt>
                    <dd>
                      <span className="eq-tag is-green" data-testid="review-quantity">
                        <FolderAddOutlined />
                        {values?.quantity
                          ? `${formatNumber(values.quantity)} ${values.unit ?? ''}`.trim()
                          : '-'}
                      </span>
                    </dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>สีหลักของวัตถุ</dt>
                    <dd>
                      <span className="eq-tag is-purple" data-testid="review-color">
                        <BgColorsOutlined />
                        {values?.color || '-'}
                      </span>
                    </dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>หน่วยงานผู้รับผิดชอบ</dt>
                    <dd>{values?.department || empty}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>ราคาต่อหน่วย</dt>
                    <dd data-testid="review-price">{formatCurrency(values?.price ?? 0)}</dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>วันที่จัดซื้อ</dt>
                    <dd>
                      {values?.purchasedAt ? dayjs(values.purchasedAt).format('DD/MM/YYYY') : empty}
                    </dd>
                  </div>
                  <div className="eq-review__item">
                    <dt>สถานะ</dt>
                    <dd>
                      <StatusPill tone={STATUS_TONE[values?.status ?? 'ready']} testId="review-status">
                        {EQUIPMENT_STATUS_LABEL[values?.status ?? 'ready']}
                      </StatusPill>
                    </dd>
                  </div>
                  <div className="eq-review__item is-full">
                    <dt>รายละเอียดเพิ่มเติม</dt>
                    <dd className="eq-review__desc">{values?.description || '-'}</dd>
                  </div>
                </dl>
              </div>

              <hr className="eq-review__rule" />

              <div className="eq-review__group is-media">
                <header className="eq-review__head">
                  <h2 className="eq-panel__title">รูปภาพครุภัณฑ์ที่อัปโหลดแล้ว</h2>
                  <button
                    type="button"
                    className="eq-chip"
                    data-testid="review-edit-media"
                    onClick={() => setStep(1)}
                  >
                    จัดการรูปภาพ
                  </button>
                </header>
                {files.length > 0 ? (
                  <ul className="eq-thumbs" data-testid="review-files">
                    {files.map((file, index) => (
                      <li key={file.uid} className="eq-thumb">
                        <img src={file.url} alt="" className="eq-thumb__img" />
                        <div className="eq-thumb__meta">
                          <strong title={file.name}>{file.name}</strong>
                          <small>
                            {formatSize(file.size)} • {index === 0 ? 'หลัก' : 'เสริม'}
                          </small>
                        </div>
                        <UploadOutlined className="eq-thumb__icon" aria-hidden />
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="eq-review__none">ยังไม่มีรูปภาพ (ไม่บังคับ)</p>
                )}
              </div>
            </div>
          </Form>
        </section>
      </div>

      <footer className="eq-footer">
        <div className="eq-footer__progress" data-testid="wizard-progress">
          <span className="eq-footer__label">Product completion</span>
          <span className="eq-footer__pct">{completion}%</span>
          <Progress
            percent={completion}
            showInfo={false}
            size={[100, 6]}
            strokeColor="#10b981"
            railColor="#e2e8f0"
            className="eq-footer__bar"
          />
        </div>

        <div className="eq-footer__actions">
          <button
            type="button"
            className="eq-footer__draft"
            data-testid="wizard-draft"
            disabled={save.isPending}
            onClick={askDraft}
          >
            Save as Draft
          </button>
          <Button
            className="eq-btn eq-btn--outline"
            data-testid="wizard-cancel"
            onClick={() => setModal('cancel')}
          >
            ยกเลิก
          </Button>
          {step > 0 && (
            <Button
              className="eq-btn eq-btn--outline"
              data-testid="wizard-back"
              onClick={() => setStep((s) => s - 1)}
            >
              ย้อนกลับ
            </Button>
          )}
          {isLast ? (
            <Button
              className="eq-btn eq-btn--primary"
              data-testid="wizard-submit"
              loading={save.isPending}
              onClick={() => void askSubmit()}
            >
              ยืนยันบันทึกข้อมูล
            </Button>
          ) : (
            <Button
              className="eq-btn eq-btn--primary"
              data-testid="wizard-next"
              onClick={() => void next()}
            >
              ถัดไป
            </Button>
          )}
        </div>
      </footer>

      <ConfirmModal
        open={modal === 'confirm'}
        variant="confirm"
        title="ยืนยันการบันทึกข้อมูล ?"
        description="โปรดตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยัน"
        okText="ยืนยัน"
        loading={save.isPending}
        onOk={() => void submit()}
        onCancel={() => setModal(null)}
        testId="wizard-confirm"
      />
      <ConfirmModal
        open={modal === 'draft'}
        variant="draft"
        title="ต้องการบันทึกเป็นฉบับร่างใช่ไหม?"
        description="ข้อมูลที่กรอกไว้จะถูกบันทึก และคุณสามารถกลับมาแก้ไขได้ภายหลัง"
        okText="ยืนยัน"
        loading={save.isPending}
        onOk={saveDraft}
        onCancel={() => setModal(null)}
        testId="wizard-draft-modal"
      />
      <ConfirmModal
        open={modal === 'cancel'}
        variant="danger"
        title="ต้องการยกเลิกรายการบันทึก?"
        description="ข้อมูลที่กรอกไว้ทั้งหมดจะถูกลบ และไม่สามารถกู้คืนได้"
        okText="ลบ"
        onOk={discard}
        onCancel={() => setModal(null)}
        testId="wizard-cancel-modal"
      />
    </div>
  )
}
