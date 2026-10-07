import { Layout, Menu } from 'antd'
import { LeftOutlined, RightOutlined } from '@ant-design/icons'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/app/store/auth.store'
import { BrandLogo } from '@/shared/components/brand-logo'
import { UserAvatar } from '@/shared/components/user-avatar'
import { MAIN_MENU, SECONDARY_MENU, type NavItem } from './menu-items'

const { Sider } = Layout

interface AppSidebarProps {
  collapsed: boolean
  onToggle: () => void
}

export function AppSidebar({ collapsed, onToggle }: AppSidebarProps) {
  const user = useAuthStore((s) => s.user)
  const navigate = useNavigate()
  const { pathname } = useLocation()

  // /equipment/new ต้องไม่ทำให้ Dashboard ('/') ถูกเลือกไปด้วย
  const selected =
    [...MAIN_MENU, ...SECONDARY_MENU]
      .map((item) => item.key)
      .filter((key) => key !== '/' && pathname.startsWith(key))
      .sort((a, b) => b.length - a.length)[0] ?? (pathname === '/' ? '/' : '')

  const toItems = (items: NavItem[]) =>
    items.map((item) => ({
      key: item.key,
      icon: (
        <span className="app-sider__icon">
          {item.icon}
          {item.dot && <i className="app-sider__dot" />}
        </span>
      ),
      label: (
        <Link to={item.key} data-testid={`nav-${item.key === '/' ? 'dashboard' : item.key.slice(1).replace(/\//g, '-')}`}>
          {item.label}
        </Link>
      ),
    }))

  return (
    <Sider
      width={256}
      collapsedWidth={76}
      collapsed={collapsed}
      theme="light"
      className="app-sider"
      data-testid="app-sidebar"
    >
      <div className="app-sider__brand">
        <BrandLogo size={32} />
        {!collapsed && <span className="app-sider__wordmark">RP.Rent</span>}
        <button
          type="button"
          className="app-sider__toggle"
          aria-label={collapsed ? 'ขยายเมนู' : 'ย่อเมนู'}
          data-testid="sidebar-toggle"
          onClick={onToggle}
        >
          {collapsed ? <RightOutlined /> : <LeftOutlined />}
        </button>
      </div>

      <div className="app-sider__main">
        <Menu mode="inline" selectedKeys={[selected]} items={toItems(MAIN_MENU)} />
        <hr className="app-sider__divider" />
        <Menu mode="inline" selectedKeys={[selected]} items={toItems(SECONDARY_MENU)} />
      </div>

      <button
        type="button"
        className="app-sider__foot"
        onClick={() => navigate('/settings')}
        aria-label="ตั้งค่าโปรไฟล์"
      >
        <UserAvatar name={user?.name} size={40} self />
        {!collapsed && (
          <>
            <span className="app-sider__foot-text">
              <small>Welcome back 👋</small>
              <strong data-testid="sidebar-user">{user?.name}</strong>
            </span>
            <RightOutlined className="app-sider__caret" />
          </>
        )}
      </button>
    </Sider>
  )
}
