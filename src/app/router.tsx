import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import { LoginPage } from '@/features/auth/pages/login-page'
import { CalendarPage } from '@/features/dashboard/pages/calendar-page'
import { DashboardPage } from '@/features/dashboard/pages/dashboard-page'
import { NotificationsPage } from '@/features/dashboard/pages/notifications-page'
import { EquipmentFormPage } from '@/features/equipment/pages/equipment-form-page'
import { EquipmentListPage } from '@/features/equipment/pages/equipment-list-page'
import { SettingsPage } from '@/features/settings/pages/settings-page'
import { BorrowFormPage } from '@/features/transactions/pages/borrow-form-page'
import { BorrowPage } from '@/features/transactions/pages/borrow-page'
import { ReturnIntakePage } from '@/features/transactions/pages/return-intake-page'
import { ReturnPage } from '@/features/transactions/pages/return-page'
import { RequireAuth } from './guards/require-auth'
import { RootLayout } from './layouts/root-layout'
import { NotFoundPage } from './not-found-page'

/** Routes — path ต้องตรงกับ key ของเมนูใน menu-items.tsx */
const router = createBrowserRouter([
  { path: '/login', element: <LoginPage /> },
  {
    path: '/',
    element: (
      <RequireAuth>
        <RootLayout />
      </RequireAuth>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'equipment/new', element: <EquipmentFormPage /> },
      { path: 'borrow', element: <BorrowPage /> },
      { path: 'borrow/new', element: <BorrowFormPage /> },
      { path: 'return', element: <ReturnPage /> },
      { path: 'return/new', element: <ReturnIntakePage /> },
      { path: 'calendar', element: <CalendarPage /> },
      { path: 'reports', element: <EquipmentListPage /> },
      { path: 'notifications', element: <NotificationsPage /> },
      { path: 'settings', element: <SettingsPage /> },
      { path: '*', element: <NotFoundPage /> },
    ],
  },
])

export function AppRouter() {
  return <RouterProvider router={router} />
}
