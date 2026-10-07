import { Avatar } from 'antd'
import { avatarColor } from '@/shared/utils/format'

interface UserAvatarProps {
  name?: string | null
  size?: number
  /** true = ใช้สีเหลืองแบบ avatar ของผู้ใช้ปัจจุบันในดีไซน์ */
  self?: boolean
}

/** avatar วงกลมตัวอักษรแรกของชื่อ — ดีไซน์ใช้รูปการ์ตูน แต่ระบบยังไม่มีรูปโปรไฟล์ */
export function UserAvatar({ name, size = 40, self = false }: UserAvatarProps) {
  const label = name?.trim() || '?'
  return (
    <Avatar
      size={size}
      className="user-avatar"
      style={{ background: self ? '#ffb31f' : avatarColor(label), flexShrink: 0 }}
    >
      {label.charAt(0).toUpperCase()}
    </Avatar>
  )
}
