import {
  AppstoreAddOutlined,
  AppstoreOutlined,
  BellOutlined,
  CalendarOutlined,
  CodeSandboxOutlined,
  FundProjectionScreenOutlined,
  SettingOutlined,
  SwapOutlined,
} from '@ant-design/icons'
import type { ReactNode } from 'react'

export interface NavItem {
  key: string
  icon: ReactNode
  label: string
  /** จุดสีส้มที่มุมไอคอน (มีรายการใหม่) */
  dot?: boolean
}

/** เมนูหลัก — key ต้องตรงกับ path ใน router.tsx เพื่อไฮไลต์เมนูตามหน้าปัจจุบัน */
export const MAIN_MENU: NavItem[] = [
  { key: '/', icon: <AppstoreOutlined />, label: 'Dashboard' },
  { key: '/equipment/new', icon: <AppstoreAddOutlined />, label: 'Add Products' },
  { key: '/borrow', icon: <CodeSandboxOutlined />, label: 'Borrow' },
  { key: '/return', icon: <SwapOutlined />, label: 'Return' },
  { key: '/calendar', icon: <CalendarOutlined />, label: 'Calendar' },
  { key: '/reports', icon: <FundProjectionScreenOutlined />, label: 'Product Reports' },
]

export const SECONDARY_MENU: NavItem[] = [
  { key: '/notifications', icon: <BellOutlined />, label: 'Notifications', dot: true },
  { key: '/settings', icon: <SettingOutlined />, label: 'Settings' },
]
