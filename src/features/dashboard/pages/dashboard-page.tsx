import '../dashboard.css'
import { Alert, Button, Dropdown, Select, Skeleton, Table, Tag } from 'antd'
import { DownOutlined, EllipsisOutlined, FallOutlined, RiseOutlined, UserOutlined } from '@ant-design/icons'
import { useQuery } from '@tanstack/react-query'
import type { ColumnsType } from 'antd/es/table'
import { useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { STATUS_COLOR } from '@/app/theme'
import { getErrorMessage } from '@/shared/api/http'
import { StatCard } from '@/shared/components/stat-card'
import { UserAvatar } from '@/shared/components/user-avatar'
import { formatChange, formatDate, formatNumber, formatRelative } from '@/shared/utils/format'
import {
  dashboardApi,
  type DashboardRange,
  type SummaryCard,
} from '../api/dashboard.api'
import type { Transaction } from '@/features/transactions/types'
import { TRANSACTION_STATUS_LABEL, TRANSACTION_TYPE_LABEL } from '@/features/transactions/types'
import { PopularList, UsageChart, YearlyChart } from '../components/dashboard-charts'

const RANGE_OPTIONS: { value: DashboardRange; label: string }[] = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: 'This week' },
  { value: 'month', label: 'This month' },
  { value: 'year', label: 'This year' },
]

/** ชื่อเดือนปัจจุบันภาษาไทย เช่น "กันยายน" */
const CURRENT_MONTH = new Date().toLocaleDateString('th-TH', { month: 'long' })

export function DashboardPage() {
  const navigate = useNavigate()
  const [range, setRange] = useState<DashboardRange>('month')

  const summary = useQuery({
    queryKey: ['dashboard', 'summary', range],
    queryFn: () => dashboardApi.summary(range),
  })
  const activities = useQuery({
    queryKey: ['dashboard', 'activities'],
    queryFn: () => dashboardApi.activities(5),
  })
  const notifications = useQuery({
    queryKey: ['dashboard', 'notifications'],
    queryFn: () => dashboardApi.notifications(4),
  })
  const members = useQuery({
    queryKey: ['dashboard', 'members'],
    queryFn: () => dashboardApi.members(6),
  })

  if (summary.isError) {
    return (
      <Alert
        type="error"
        showIcon
        data-testid="dashboard-error"
        message="โหลดข้อมูลแดชบอร์ดไม่สำเร็จ"
        description={getErrorMessage(summary.error)}
      />
    )
  }

  return (
    <div className="dashboard" data-testid="dashboard-page">
      <div className="dashboard__main">
        <div className="dashboard__toolbar">
          <h1 className="dashboard__title">Dashboard</h1>
          <Select
            data-testid="dashboard-range"
            className="dashboard__range"
            value={range}
            onChange={setRange}
            options={RANGE_OPTIONS}
            variant="borderless"
            size="small"
            suffixIcon={<DownOutlined />}
            popupMatchSelectWidth={false}
            placement="bottomRight"
          />
        </div>

        <div className="dashboard__body">
          <section className="stat-row dashboard__stats" data-testid="stat-grid">
            {summary.isLoading
              ? Array.from({ length: 4 }, (_, i) => (
                  <div key={i} className={`stat-card stat-card--${i % 2 ? 'sky' : 'lavender'}`}>
                    <Skeleton active paragraph={{ rows: 1 }} title={false} />
                  </div>
                ))
              : summary.data?.cards.map((card, i) => <StatTile key={card.key} card={card} index={i} />)}
          </section>

          <section className="dashboard__charts">
            <div className="dash-block">
              <div className="dash-block__head">
                <h2 className="dash-block__title">การใช้งาน</h2>
                <span className="chart-legend">
                  <i className="chart-legend__dot" /> ประจำเดือน{CURRENT_MONTH}
                </span>
              </div>
              {summary.isLoading ? <Skeleton active /> : <UsageChart data={summary.data?.usage ?? []} />}
            </div>

            <div className="dash-block">
              <div className="dash-block__head">
                <h2 className="dash-block__title is-light">ครุภัณฑ์ยอดนิยม</h2>
              </div>
              {summary.isLoading ? <Skeleton active /> : <PopularList data={summary.data?.popular ?? []} />}
            </div>
          </section>

          <section className="dash-block">
            <div className="dash-block__head">
              <h2 className="dash-block__title">สถิติประจำปี {new Date().getFullYear()}</h2>
            </div>
            {summary.isLoading ? <Skeleton active /> : <YearlyChart data={summary.data?.yearly ?? []} />}
          </section>

          <section className="dash-block dash-block--recent">
            <div className="dash-block__head">
              <h2 className="dash-block__title is-lg">รายการล่าสุด</h2>
              <Dropdown
                trigger={['click']}
                placement="bottomRight"
                menu={{
                  items: [
                    { key: '/borrow', label: 'ดูรายการยืมทั้งหมด' },
                    { key: '/return', label: 'ดูรายการคืนทั้งหมด' },
                  ],
                  onClick: ({ key }) => navigate(key),
                }}
              >
                <Button
                  className="dash-more"
                  shape="circle"
                  icon={<EllipsisOutlined />}
                  aria-label="ตัวเลือกเพิ่มเติม"
                  data-testid="recent-more"
                />
              </Dropdown>
            </div>
            <Table<Transaction>
              data-testid="recent-table"
              className="recent-table"
              rowKey="id"
              pagination={false}
              loading={summary.isLoading}
              dataSource={summary.data?.recent ?? []}
              columns={RECENT_COLUMNS}
              rowClassName={(_, index) => (index % 2 === 0 ? 'is-striped' : '')}
              scroll={{ x: 720 }}
            />
          </section>
        </div>
      </div>

      <aside className="dashboard__rail">
        <RailSection title="การแจ้งเตือน" testId="rail-notifications" loading={notifications.isLoading}>
          {notifications.data?.items.map((item) => (
            <RailRow
              key={item.id}
              icon={
                <span className="rail-row__icon">
                  <UserOutlined />
                </span>
              }
              name={item.message}
              time={formatRelative(item.createdAt)}
            />
          ))}
        </RailSection>

        <RailSection title="ประวัติการทำรายการในระบบ" testId="rail-activities" loading={activities.isLoading}>
          <div className="rail-timeline">
            {activities.data?.map((item) => (
              <RailRow
                key={item.id}
                icon={<UserAvatar name={item.actorName} size={24} />}
                name={item.actorName}
                detail={item.message}
                time={formatRelative(item.createdAt)}
                thai
              />
            ))}
          </div>
        </RailSection>

        <RailSection title="สมาชิก" testId="rail-members" loading={members.isLoading}>
          {members.data?.map((member) => (
            <RailRow key={member.id} icon={<UserAvatar name={member.name} size={24} />} name={member.name} />
          ))}
        </RailSection>
      </aside>
    </div>
  )
}

function StatTile({ card, index }: { card: SummaryCard; index: number }) {
  const up = card.change >= 0
  return (
    <StatCard
      tint={index % 2 ? 'sky' : 'lavender'}
      testId={`stat-${card.key}`}
      valueTestId={`stat-${card.key}-value`}
      label={card.label}
      value={formatNumber(card.value)}
      hint={
        <span className="stat-trend">
          {formatChange(card.change)}
          {up ? <RiseOutlined /> : <FallOutlined />}
        </span>
      }
    />
  )
}

function RailSection({
  title,
  testId,
  loading,
  children,
}: {
  title: string
  testId: string
  loading: boolean
  children: ReactNode
}) {
  return (
    <section className="rail-section" data-testid={testId}>
      <h4 className="rail-section__title">{title}</h4>
      {loading ? <Skeleton active paragraph={{ rows: 3 }} title={false} /> : children}
    </section>
  )
}

function RailRow({
  icon,
  name,
  detail,
  time,
  thai = false,
}: {
  icon: ReactNode
  name: string
  detail?: string
  time?: string
  /** true = ชื่อ/รายละเอียดใช้ IBM Plex Sans Thai (ประวัติการทำรายการ) */
  thai?: boolean
}) {
  return (
    <div className={`rail-row${thai ? ' is-thai' : ''}`}>
      {icon}
      <div className="rail-row__text">
        <strong title={name}>{name}</strong>
        {detail && <span title={detail}>{detail}</span>}
        {time && <small>{time}</small>}
      </div>
    </div>
  )
}

const RECENT_COLUMNS: ColumnsType<Transaction> = [
  {
    title: 'ชื่อ',
    dataIndex: 'userName',
    width: '26%',
    render: (value: string) => (
      <span className="cell-user">
        <UserAvatar name={value} size={24} />
        <span className="cell-user__name">{value}</span>
      </span>
    ),
  },
  { title: 'ครุภัณฑ์', dataIndex: 'equipmentName', width: '15%', ellipsis: true },
  { title: 'รหัสครุภัณฑ์', dataIndex: 'code', width: '15%' },
  {
    title: 'ประเภท',
    dataIndex: 'type',
    width: '12%',
    render: (value: Transaction['type']) => TRANSACTION_TYPE_LABEL[value],
  },
  {
    title: 'วันที่',
    dataIndex: 'occurredAt',
    width: '15%',
    render: (value: string) => formatDate(value),
  },
  {
    title: 'สถานะการดำเนินการ',
    dataIndex: 'status',
    width: '17%',
    render: (value: Transaction['status']) => {
      const color = STATUS_COLOR[value]
      return (
        <Tag
          data-testid={`status-${value}`}
          className="status-chip"
          style={{ background: color.bg, color: color.fg, borderColor: color.fg }}
        >
          {TRANSACTION_STATUS_LABEL[value]}
        </Tag>
      )
    },
  },
]
