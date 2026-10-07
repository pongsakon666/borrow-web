import type { PropsWithChildren } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { ConfigProvider, App as AntdApp } from 'antd'
import { antdTheme } from './theme'
import thTH from 'antd/locale/th_TH'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import { queryClient } from './query-client'

dayjs.locale('th')

/**
 * Global providers — TanStack Query · antd ConfigProvider (locale th) · antd App (message/notification/modal)
 * Router อยู่ที่ router.tsx แยกออกมาเพื่อให้ test render component ได้โดยไม่ต้องห่อ router
 */
export function AppProviders({
  children,
  client = queryClient,
}: PropsWithChildren<{ client?: QueryClient }>) {
  return (
    <QueryClientProvider client={client}>
      <ConfigProvider locale={thTH} theme={antdTheme}>
        <AntdApp>{children}</AntdApp>
      </ConfigProvider>
      {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
    </QueryClientProvider>
  )
}
