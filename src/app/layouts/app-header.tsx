import { Badge, Button, Dropdown, Layout } from 'antd'
import { BellFilled, LogoutOutlined, UserOutlined } from '@ant-design/icons'
import { useQuery } from '@tanstack/react-query'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/app/store/auth.store'
import { dashboardApi } from '@/features/dashboard/api/dashboard.api'
import { useLogout } from '@/features/auth/hooks/use-logout'
import { UserAvatar } from '@/shared/components/user-avatar'
import { MAIN_MENU, SECONDARY_MENU } from './menu-items'

const { Header } = Layout

const ROLE_LABEL: Record<string, string> = {
  admin: 'Admin',
  staff: 'Staff',
  user: 'Member',
}

/** ชื่อหน้าปัจจุบัน — มาจากเมนูด้านซ้าย (ต้องดูทั้งเมนูหลักและเมนูรอง) */
function usePageTitle(): string {
  const { pathname } = useLocation()
  if (pathname === '/') return 'Dashboard'
  const match = [...MAIN_MENU, ...SECONDARY_MENU]
    .filter((item) => item.key !== '/' && pathname.startsWith(item.key))
    .sort((a, b) => b.key.length - a.key.length)[0]
  return match?.label ?? 'Dashboard'
}

export function AppHeader() {
  const user = useAuthStore((s) => s.user)
  const navigate = useNavigate()
  const logout = useLogout()
  const title = usePageTitle()

  const { data } = useQuery({
    queryKey: ['notifications', 'badge'],
    queryFn: () => dashboardApi.notifications(6),
    staleTime: 60_000,
  })

  return (
    <Header className="app-header">
      {/* ดีไซน์ไม่มีชื่อหน้าบน header — เก็บไว้ให้ screen reader และ E2E อ่าน */}
      <span className="sr-only" data-testid="page-title">
        {title}
      </span>

      <div className="app-header__right">
        <Badge count={data?.unread ?? 0} size="small" offset={[-4, 4]} color="#f93c65">
          <Button
            type="text"
            shape="circle"
            className="app-header__bell"
            icon={<BellFilled />}
            aria-label="การแจ้งเตือน"
            data-testid="header-bell"
            onClick={() => navigate('/notifications')}
          />
        </Badge>

        <span className="app-header__lang" data-testid="header-lang">
          <button type="button" className="is-active">
            EN
          </button>
          <i>|</i>
          <button type="button">TH</button>
        </span>

        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'profile',
                icon: <UserOutlined />,
                label: <span data-testid="menu-profile">โปรไฟล์ของฉัน</span>,
                onClick: () => navigate('/settings'),
              },
              { type: 'divider' },
              {
                key: 'logout',
                icon: <LogoutOutlined />,
                danger: true,
                label: <span data-testid="logout-button">ออกจากระบบ</span>,
                onClick: () => void logout(),
              },
            ],
          }}
        >
          <button type="button" className="app-header__user" data-testid="header-user-menu">
            <UserAvatar name={user?.name} size={40} self />
            <span className="app-header__user-text">
              <strong data-testid="header-user">{user?.name}</strong>
              <small>{ROLE_LABEL[user?.role ?? ''] ?? user?.role}</small>
            </span>
          </button>
        </Dropdown>
      </div>
    </Header>
  )
}
