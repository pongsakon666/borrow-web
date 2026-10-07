import { useState } from 'react'
import { Layout } from 'antd'
import { Outlet } from 'react-router-dom'
import { AppHeader } from './app-header'
import { AppSidebar } from './app-sidebar'

const { Content } = Layout

/** Layout หลังล็อกอิน — sidebar ซ้าย · header บน · เนื้อหาตรงกลาง */
export function RootLayout() {
  const [collapsed, setCollapsed] = useState(false)

  return (
    <Layout className="app-layout">
      <AppSidebar collapsed={collapsed} onToggle={() => setCollapsed((v) => !v)} />
      <Layout>
        <AppHeader />
        <Content className="app-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
