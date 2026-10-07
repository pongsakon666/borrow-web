import { useState } from 'react'
import { App, Button, Empty, Segmented, Spin } from 'antd'
import { CheckOutlined } from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { http } from '@/shared/api/http'
import { formatRelative } from '@/shared/utils/format'
import { PageHeader } from '@/shared/components/page-header'
import { SectionCard } from '@/shared/components/section-card'
import { UserAvatar } from '@/shared/components/user-avatar'
import { dashboardApi } from '../api/dashboard.api'
import '../notifications.css'

type View = 'all' | 'unread'

/** หน้าการแจ้งเตือนทั้งหมด — data-testid = notifications-page / notification-item / mark-all-read */
export function NotificationsPage() {
  const queryClient = useQueryClient()
  const { message } = App.useApp()
  const [view, setView] = useState<View>('all')

  const query = useQuery({
    queryKey: ['notifications', 'page'],
    queryFn: () => dashboardApi.notifications(50),
  })

  const markAll = useMutation({
    mutationFn: () => http.post('/notifications/read-all'),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['notifications'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      message.success('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด')
    },
  })

  const unread = query.data?.unread ?? 0
  const items = (query.data?.items ?? []).filter((item) => view === 'all' || !item.isRead)

  return (
    <div className="page nt-page" data-testid="notifications-page">
      <PageHeader
        title="การแจ้งเตือน"
        subtitle="ติดตามความเคลื่อนไหวของการยืม-คืนครุภัณฑ์ล่าสุด"
        actions={
          <Button
            type="primary"
            className="nt-read-all"
            icon={<CheckOutlined />}
            data-testid="mark-all-read"
            loading={markAll.isPending}
            disabled={unread === 0}
            onClick={() => markAll.mutate()}
          >
            อ่านทั้งหมด
          </Button>
        }
      />

      <SectionCard
        title="Notifications"
        accent
        badge={unread > 0 ? `${unread} ยังไม่อ่าน` : undefined}
        badgeTone="pink"
        extra={
          <Segmented<View>
            className="nt-view"
            value={view}
            onChange={setView}
            options={[
              { value: 'all', label: 'ทั้งหมด' },
              { value: 'unread', label: 'ยังไม่อ่าน' },
            ]}
          />
        }
      >
        <Spin spinning={query.isLoading}>
          {items.length === 0 ? (
            <Empty
              className="nt-empty"
              image={Empty.PRESENTED_IMAGE_SIMPLE}
              description={
                view === 'unread' ? 'ไม่มีการแจ้งเตือนที่ยังไม่อ่าน' : 'ยังไม่มีการแจ้งเตือน'
              }
            />
          ) : (
            <ul className="nt-list">
              {items.map((item) => (
                <li
                  key={item.id}
                  className={`nt-item${item.isRead ? '' : ' is-unread'}`}
                  data-testid="notification-item"
                >
                  <UserAvatar name={item.actorName} size={40} />
                  <div className="nt-item__text">
                    <p>{item.message}</p>
                    <small>
                      {item.actorName} · {formatRelative(item.createdAt)}
                    </small>
                  </div>
                  {!item.isRead && <i className="nt-item__dot" aria-label="ยังไม่อ่าน" />}
                </li>
              ))}
            </ul>
          )}
        </Spin>
      </SectionCard>
    </div>
  )
}
