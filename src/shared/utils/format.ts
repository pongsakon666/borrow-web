import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/th'

dayjs.extend(relativeTime)

/** 7,265 */
export const formatNumber = (value: number) => new Intl.NumberFormat('th-TH').format(value)

/** ฿7,800 */
export const formatCurrency = (value: number) =>
  new Intl.NumberFormat('th-TH', { style: 'currency', currency: 'THB', maximumFractionDigits: 0 })
    .format(value)

/** Jun 24, 2026 — ใช้ locale อังกฤษให้ตรงกับตารางในดีไซน์ */
export const formatDate = (value?: string | null) =>
  value ? dayjs(value).locale('en').format('MMM D, YYYY') : '-'

/** 59 minutes ago */
export const formatRelative = (value?: string | null) =>
  value ? dayjs(value).locale('en').fromNow() : '-'

/** +11.01% / -0.03% */
export const formatChange = (value: number) => `${value > 0 ? '+' : ''}${value.toFixed(2)}%`

/** สีพื้น avatar จากชื่อ — คนเดิมได้สีเดิมเสมอ */
const AVATAR_COLORS = ['#f0b3a0', '#a7c7e7', '#b8e0c8', '#d4c5f9', '#f9d5a7', '#c5d9f1']
export function avatarColor(name: string): string {
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = (hash * 31 + name.charCodeAt(i)) | 0
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}
