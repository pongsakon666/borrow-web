import { useState } from 'react'
import { App, Avatar, Button, Input, Switch } from 'antd'
import { CameraFilled } from '@ant-design/icons'
import { useAuthStore } from '@/app/store/auth.store'
import { avatarColor } from '@/shared/utils/format'
import '../settings.css'

const ROLE_LABEL: Record<string, string> = {
  admin: 'ผู้ดูแลระบบ',
  staff: 'เจ้าหน้าที่',
  user: 'ผู้ใช้ทั่วไป',
}

const PREFERENCES = [
  {
    key: 'email',
    title: 'Email Notifications',
    desc: 'Receive summary digests, project updates, and security alerts directly in your inbox.',
  },
  {
    key: 'dark',
    title: 'Dark Mode',
    desc: 'Optimize system interface contrast to minimize eye strain in dark environments.',
  },
  {
    key: 'twoFactor',
    title: 'Two-Factor Authentication',
    desc: 'Keep your administrative console safe by requiring a secondary verification token on logins.',
  },
] as const

type PrefKey = (typeof PREFERENCES)[number]['key']

/**
 * หน้าตั้งค่าโปรไฟล์ — ยังไม่มี API แก้ไขโปรไฟล์ ค่าที่แก้จึงเก็บใน state ของหน้าเท่านั้น
 * selector สำหรับ Robot: data-testid = settings-page / settings-user-email
 */
export function SettingsPage() {
  const { message } = App.useApp()
  const user = useAuthStore((s) => s.user)
  const [name, setName] = useState(user?.name ?? '')
  const [phone, setPhone] = useState('')
  const [prefs, setPrefs] = useState<Record<PrefKey, boolean>>({
    email: true,
    dark: false,
    twoFactor: true,
  })

  const save = () => {
    // TODO: เชื่อม API เมื่อ BE มี endpoint แก้ไขโปรไฟล์
    message.success('บันทึกการตั้งค่าแล้ว (เฉพาะในหน้านี้)')
  }

  return (
    <div className="page" data-testid="settings-page">
      <section className="st-card">
        <header className="st-head">
          <h1>Profile Settings</h1>
          <p>Update your personal information, avatar, and core system preferences.</p>
        </header>

        <hr className="st-line" />

        <div className="st-avatar">
          <div className="st-avatar__pic">
            <Avatar size={80} style={{ background: avatarColor(user?.name ?? ''), fontSize: 30 }}>
              {user?.name?.charAt(0).toUpperCase() ?? '?'}
            </Avatar>
            <button
              type="button"
              className="st-avatar__badge"
              aria-label="เปลี่ยนรูปโปรไฟล์"
              data-testid="settings-avatar-badge"
              onClick={() => message.info('ยังไม่รองรับการอัปโหลดรูปโปรไฟล์')}
            >
              <CameraFilled />
            </button>
          </div>
          <div className="st-avatar__text">
            <strong data-testid="settings-user-name">{user?.name ?? '-'}</strong>
            <span>PNG, JPG or GIF up to 5MB. Recommended size 400x400px.</span>
          </div>
        </div>

        <div className="st-fields">
          <label className="st-field">
            <span>Full Name</span>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              data-testid="settings-name-input"
            />
          </label>
          <div className="st-field">
            <span>Email Address</span>
            {/* อีเมลแก้ไม่ได้ — แสดงเป็นข้อความเพื่อให้ Robot อ่านค่าได้ตรง */}
            <div className="st-readonly" data-testid="settings-user-email">
              {user?.email}
            </div>
          </div>
          <label className="st-field">
            <span>Phone Number</span>
            <Input
              value={phone}
              placeholder="-"
              onChange={(e) => setPhone(e.target.value)}
              data-testid="settings-phone-input"
            />
          </label>
          <div className="st-field">
            <span>Role</span>
            <div className="st-readonly" data-testid="settings-user-role">
              {ROLE_LABEL[user?.role ?? ''] ?? user?.role ?? '-'}
            </div>
          </div>
        </div>

        <div className="st-prefs">
          <h2>Preferences</h2>
          <hr className="st-line" />
          <ul>
            {PREFERENCES.map((p) => (
              <li key={p.key}>
                <div>
                  <strong>{p.title}</strong>
                  <span>{p.desc}</span>
                </div>
                <Switch
                  size="small"
                  className="st-switch"
                  checked={prefs[p.key]}
                  aria-label={p.title}
                  data-testid={`settings-pref-${p.key}`}
                  onChange={(checked) => setPrefs((s) => ({ ...s, [p.key]: checked }))}
                />
              </li>
            ))}
          </ul>
        </div>

        <div className="st-actions">
          <Button type="primary" className="st-save" onClick={save} data-testid="settings-save">
            Save Changes
          </Button>
        </div>
      </section>
    </div>
  )
}
