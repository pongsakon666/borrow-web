import dayjs from 'dayjs'
import type { Tone } from '@/app/theme'
import type { Transaction, TransactionStatus } from './types'

/** สถานะ transaction → ป้ายภาษาไทยตามดีไซน์หน้า Borrow */
export const BORROW_STATUS: Record<TransactionStatus, { label: string; tone: Tone }> = {
  pending: { label: 'รอรับของ', tone: 'pink' },
  approved: { label: 'รอรับของ', tone: 'pink' },
  in_progress: { label: 'กำลังยืม', tone: 'purple' },
  complete: { label: 'จ่ายแล้ว', tone: 'green' },
  rejected: { label: 'ยกเลิกแล้ว', tone: 'gray' },
}

/** ช่องทางการจอง — API ไม่มี field นี้ เก็บลง note แทน */
export const BORROW_CHANNELS = [
  { value: 'walk-in', label: 'Walk-in (ติดต่อหน้าเคาน์เตอร์)', short: 'Walk-in' },
  { value: 'online', label: 'จองผ่านระบบ', short: 'จองผ่านระบบ' },
  { value: 'phone', label: 'จองทางโทรศัพท์', short: 'จองทางโทรศัพท์' },
] as const

export type BorrowChannel = (typeof BORROW_CHANNELS)[number]['value']

/** ข้อมูลที่ API ไม่รองรับ → เขียนเป็นบรรทัด "หัวข้อ: ค่า" ใน note */
export interface BorrowNoteFields {
  booker?: string
  phone?: string
  department?: string
  pickupDate?: string
  channel?: string
  color?: string
  category?: string
  subCategory?: string
  details?: string
  remark?: string
}

const NOTE_KEYS: [keyof BorrowNoteFields, string][] = [
  ['booker', 'ผู้จอง'],
  ['phone', 'เบอร์โทร'],
  ['department', 'หน่วยงาน'],
  ['pickupDate', 'วันที่รับ'],
  ['channel', 'ช่องทาง'],
  ['color', 'สี'],
  ['category', 'หมวดหมู่หลัก'],
  ['subCategory', 'หมวดหมู่ย่อย'],
  ['details', 'รายละเอียด'],
  ['remark', 'หมายเหตุ'],
]

export function buildBorrowNote(fields: BorrowNoteFields): string {
  return NOTE_KEYS.filter(([key]) => fields[key]?.trim())
    .map(([key, label]) => `${label}: ${fields[key]!.trim()}`)
    .join('\n')
}

/** อ่าน note กลับเป็น field — บรรทัดที่ไม่มีหัวข้อจะต่อท้าย field ก่อนหน้า (รายละเอียดหลายบรรทัด) */
export function parseBorrowNote(note: string | null | undefined): BorrowNoteFields {
  const out: BorrowNoteFields = {}
  let last: keyof BorrowNoteFields | null = null
  for (const line of (note ?? '').split('\n')) {
    const hit = NOTE_KEYS.find(([, label]) => line.startsWith(`${label}: `))
    if (hit) {
      last = hit[0]
      out[last] = line.slice(hit[1].length + 2)
    } else if (last && line) {
      out[last] = `${out[last]}\n${line}`
    }
  }
  return out
}

/** Walk-in = บันทึกจากฟอร์มด้วยช่องทาง Walk-in · ที่เหลือถือเป็นการจองล่วงหน้า */
export const isWalkIn = (tx: Transaction) =>
  (parseBorrowNote(tx.note).channel ?? '').toLowerCase().startsWith('walk-in')

/** 09:00 น. */
export const formatClock = (value?: string | null) =>
  value ? `${dayjs(value).format('HH:mm')} น.` : '-'

/** 24 ต.ค. 2566 10:30 น. (ปี พ.ศ.) */
export function formatThaiDateTime(value: dayjs.Dayjs) {
  const d = value.locale('th')
  return `${d.format('D MMM')} ${d.year() + 543} ${d.format('HH:mm')} น.`
}
