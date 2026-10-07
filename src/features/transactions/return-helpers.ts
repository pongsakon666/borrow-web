import dayjs from 'dayjs'
import 'dayjs/locale/th'
import type { Tone } from '@/app/theme'
import type { Transaction, TransactionStatus } from './types'

/** ป้ายสถานะการคืน (รายการ type=return) */
export const RETURN_STATUS: Record<TransactionStatus, { label: string; tone: Tone }> = {
  pending: { label: 'รอคืนของ', tone: 'pink' },
  approved: { label: 'รอตรวจรับ', tone: 'pink' },
  in_progress: { label: 'รอเจ้าหน้าที่ตรวจ', tone: 'orange' },
  complete: { label: 'คืนสำเร็จแล้ว', tone: 'green' },
  rejected: { label: 'ไม่รับคืน', tone: 'red' },
}

/** ยังไม่ปิดงาน → แสดงปุ่ม "ยืนยันรับคืน" */
export const isAwaitingReturn = (status: TransactionStatus) =>
  status === 'pending' || status === 'approved' || status === 'in_progress'

export const RETURN_STATUS_OPTIONS = [
  { value: '', label: 'ทุกสถานะ' },
  ...(Object.keys(RETURN_STATUS) as TransactionStatus[]).map((value) => ({
    value,
    label: RETURN_STATUS[value].label,
  })),
]

/** สภาพทรัพย์สินที่รับคืน */
export type ReturnCondition = 'normal' | 'scratched' | 'damaged' | 'lost'

export const CONDITION_OPTIONS: { value: ReturnCondition; label: string }[] = [
  { value: 'normal', label: 'ใช้งานปกติ' },
  { value: 'scratched', label: 'มีรอยขีดข่วน' },
  { value: 'damaged', label: 'ชำรุด / เสียหาย' },
  { value: 'lost', label: 'สูญหาย' },
]

export const REASON_OPTIONS = [
  'หมดสัญญาเช่า',
  'ครบกำหนดยืม',
  'ย้ายทีมงาน',
  'ออกจากบริษัท',
  'เสร็จสิ้นโครงการ',
  'อื่น ๆ',
].map((value) => ({ value, label: value }))

export const conditionLabel = (value: ReturnCondition) =>
  CONDITION_OPTIONS.find((o) => o.value === value)?.label ?? value

/** ชำรุด/สูญหาย → ต้องให้เจ้าหน้าที่ตรวจต่อ (สถานะ in_progress) */
export const needsInspection = (value: ReturnCondition) => value === 'damaged' || value === 'lost'

/**
 * API ไม่มีฟิลด์สภาพ/ผู้คืน — หน้า intake เขียนลง note เป็น "สภาพ: … · เหตุผล: … · ผู้คืน: … · อ้างอิง: …"
 * แล้วหน้า list อ่านกลับด้วย parseReturnNote
 */
export interface ReturnNote {
  condition?: string
  reason?: string
  returner?: string
  ref?: string
  remark?: string
}

const NOTE_KEYS: [keyof ReturnNote, string][] = [
  ['condition', 'สภาพ'],
  ['reason', 'เหตุผล'],
  ['returner', 'ผู้คืน'],
  ['ref', 'อ้างอิง'],
  ['remark', 'หมายเหตุ'],
]

export function buildReturnNote(note: ReturnNote): string {
  return NOTE_KEYS.filter(([key]) => note[key])
    .map(([key, label]) => `${label}: ${note[key]}`)
    .join(' · ')
}

export function parseReturnNote(raw: string): ReturnNote {
  const result: ReturnNote = {}
  for (const part of (raw ?? '').split(' · ')) {
    const found = NOTE_KEYS.find(([, label]) => part.startsWith(`${label}: `))
    if (found) result[found[0]] = part.slice(found[1].length + 2).trim()
  }
  return result
}

/** ป้ายสภาพอุปกรณ์ในตาราง list */
export function conditionPill(tx: Transaction): { label: string; tone: Tone | 'neutral' } {
  const noted = parseReturnNote(tx.note).condition
  if (noted) {
    if (noted === conditionLabel('normal')) return { label: 'ปกติ (สมบูรณ์)', tone: 'green' }
    return { label: noted, tone: 'pink' }
  }
  if (tx.status === 'complete') return { label: 'ปกติ (สมบูรณ์)', tone: 'green' }
  if (tx.status === 'rejected') return { label: 'ไม่ผ่านการตรวจ', tone: 'pink' }
  return { label: 'รอการตรวจสอบ', tone: 'neutral' }
}

/** 13:00 น. */
export const formatTime = (value?: string | null) =>
  value ? `${dayjs(value).format('HH:mm')} น.` : '-'

/** 12 ต.ค. 2024 (ปี ค.ศ. ตามดีไซน์) */
export const formatThaiDate = (value?: string | null) =>
  value ? dayjs(value).locale('th').format('D MMM YYYY') : '-'

/** ช่วงเวลาของวันนี้ สำหรับ query from/to */
export function todayRange() {
  return {
    from: dayjs().startOf('day').toISOString(),
    to: dayjs().endOf('day').toISOString(),
  }
}
