import { useMemo, useState, type ReactNode } from 'react'
import { Button, Dropdown, Empty, Popover, Spin } from 'antd'
import {
  CalendarFilled,
  CheckCircleFilled,
  ClockCircleFilled,
  CloseCircleFilled,
  DownOutlined,
  LeftOutlined,
  PlayCircleFilled,
  RightOutlined,
} from '@ant-design/icons'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/shared/components/page-header'
import { UserAvatar } from '@/shared/components/user-avatar'
import { transactionsApi } from '@/features/transactions/api'
import {
  TRANSACTION_TYPE_LABEL,
  type Transaction,
  type TransactionStatus,
} from '@/features/transactions/types'
import '../calendar.css'

const WEEKDAYS = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.']

/** สถานะรายการ → ข้อความยาว (หัวการ์ด) / สั้น (pill) + สี + ไอคอน ตามดีไซน์ */
const STATUS_META: Record<
  TransactionStatus,
  { label: string; short: string; color: string; icon: ReactNode }
> = {
  complete: {
    label: 'เสร็จสิ้น',
    short: 'เสร็จสิ้น',
    color: '#424f9b',
    icon: <CheckCircleFilled />,
  },
  approved: {
    label: 'ยืนยันแล้ว',
    short: 'ยืนยันแล้ว',
    color: '#34c759',
    icon: <CalendarFilled />,
  },
  in_progress: {
    label: 'กำลังยืม',
    short: 'กำลังยืม',
    color: '#1470ff',
    icon: <PlayCircleFilled />,
  },
  pending: { label: 'รอยืนยัน', short: 'รอ', color: '#ff7d34', icon: <ClockCircleFilled /> },
  rejected: { label: 'ปฏิเสธ', short: 'ปฏิเสธ', color: '#878787', icon: <CloseCircleFilled /> },
}

/** มีนาคม 2567 — เดือนไทย + พ.ศ. */
const thaiMonth = (d: Dayjs) => `${d.locale('th').format('MMMM')} ${d.year() + 543}`
const thaiDate = (d: Dayjs) => `${d.date()} ${thaiMonth(d)}`

/** 09:00 - 10:30 · ถ้าคืนคนละวันแสดงวันที่คืนด้วย */
function timeRange(item: Transaction) {
  const start = dayjs(item.occurredAt)
  if (!item.dueAt) return `${start.format('HH:mm')} - ไม่ระบุกำหนดคืน`
  const end = dayjs(item.dueAt)
  const endText = end.isSame(start, 'day')
    ? end.format('HH:mm')
    : `${end.locale('th').format('D MMM')} ${end.format('HH:mm')}`
  return `${start.format('HH:mm')} - ${endText}`
}

function StatusLabel({ status }: { status: TransactionStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="cal-status" style={{ color: meta.color }}>
      {meta.icon}
      {meta.label}
    </span>
  )
}

function StatusChip({ status }: { status: TransactionStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="cal-chip" style={{ color: meta.color, background: `${meta.color}1a` }}>
      {meta.short}
    </span>
  )
}

/** ผู้ยืม: avatar + บรรทัดเล็ก (เลขที่รายการ/ประเภท) + ชื่อ */
function Requester({ item }: { item: Transaction }) {
  return (
    <div className="cal-person">
      <UserAvatar name={item.userName} size={40} />
      <div className="cal-person__text">
        <small>
          {TRANSACTION_TYPE_LABEL[item.type]} · {item.code}
        </small>
        <strong>{item.userName}</strong>
      </div>
    </div>
  )
}

/** popover ตอน hover วันที่มีรายการ (ดีไซน์ calendar-tooltip) */
function DayTooltip({ items }: { items: Transaction[] }) {
  return (
    <div className="cal-tip__body">
      <header className="cal-tip__head">
        <strong>รายการจองวันนี้</strong>
        <span className="cal-count">{items.length} รายการ</span>
      </header>
      <div className="cal-tip__list">
        {items.slice(0, 3).map((item) => (
          <div key={item.id} className="cal-tip__entry">
            <div className="cal-tip__row">
              <span className="cal-tip__time">{timeRange(item)}</span>
              <StatusLabel status={item.status} />
            </div>
            <div className="cal-tip__title">{item.equipmentName}</div>
            <Requester item={item} />
          </div>
        ))}
        {items.length > 3 && <div className="cal-tip__more">และอีก {items.length - 3} รายการ</div>}
      </div>
    </div>
  )
}

/**
 * ปฏิทินการจอง — ตารางเดือน (ซ้าย) + รายละเอียดวันที่เลือก (ขวา)
 * ใช้รายการยืมตามวันที่ทำรายการ (occurredAt) ของเดือนที่แสดง
 * selector สำหรับ Robot: data-testid = calendar-page
 */
export function CalendarPage() {
  const [month, setMonth] = useState(() => dayjs().startOf('month'))
  const [selected, setSelected] = useState(() => dayjs().startOf('day'))

  const { data, isLoading } = useQuery({
    queryKey: ['transactions', 'calendar', month.format('YYYY-MM')],
    queryFn: () =>
      transactionsApi.list({
        type: 'borrow',
        from: month.startOf('month').toISOString(),
        to: month.endOf('month').toISOString(),
        limit: 100,
      }),
  })

  // จัดกลุ่มตามวัน เรียงตามเวลา
  const byDate = useMemo(() => {
    const map = new Map<string, Transaction[]>()
    for (const item of data?.items ?? []) {
      const key = dayjs(item.occurredAt).format('YYYY-MM-DD')
      const list = map.get(key) ?? []
      list.push(item)
      map.set(key, list)
    }
    for (const list of map.values()) {
      list.sort((a, b) => dayjs(a.occurredAt).valueOf() - dayjs(b.occurredAt).valueOf())
    }
    return map
  }, [data])

  // ช่องว่างก่อนวันที่ 1 + วันในเดือน + ช่องว่างท้ายให้ครบแถว
  const cells = useMemo(() => {
    const offset = month.day()
    const days = month.daysInMonth()
    const total = Math.ceil((offset + days) / 7) * 7
    return Array.from({ length: total }, (_, i) => {
      const day = i - offset + 1
      return day >= 1 && day <= days ? month.date(day) : null
    })
  }, [month])

  const goMonth = (next: Dayjs) => {
    const start = next.startOf('month')
    setMonth(start)
    const today = dayjs().startOf('day')
    setSelected(today.isSame(start, 'month') ? today : start)
  }

  const agenda = byDate.get(selected.format('YYYY-MM-DD')) ?? []
  const today = dayjs()

  return (
    <div className="page cal-page" data-testid="calendar-page">
      <PageHeader
        title="ปฏิทินการจอง"
        subtitle="ดูว่าใครจองอะไรไว้บ้างในวันนี้"
        actions={
          <>
            <Link to="/borrow/new">
              <Button className="btn-pink cal-btn-new" data-testid="calendar-new">
                จองใหม่
              </Button>
            </Link>
            <Link to="/borrow">
              <Button type="primary" className="cal-btn-all" data-testid="calendar-all">
                ดูทั้งหมด
              </Button>
            </Link>
          </>
        }
      />

      <div className="cal-layout">
        <section className="cal-panel" data-testid="calendar-panel">
          <header className="cal-panel__head">
            <Dropdown
              trigger={['click']}
              menu={{
                selectable: true,
                selectedKeys: [String(month.month())],
                items: Array.from({ length: 12 }, (_, m) => ({
                  key: String(m),
                  label: thaiMonth(month.month(m)),
                })),
                onClick: ({ key }) => goMonth(month.month(Number(key))),
              }}
            >
              <button type="button" className="cal-month" data-testid="calendar-month">
                {thaiMonth(month)}
                <DownOutlined />
              </button>
            </Dropdown>
            <div className="cal-nav">
              <button
                type="button"
                aria-label="เดือนก่อนหน้า"
                data-testid="calendar-prev"
                onClick={() => goMonth(month.subtract(1, 'month'))}
              >
                <LeftOutlined />
              </button>
              <button
                type="button"
                aria-label="เดือนถัดไป"
                data-testid="calendar-next"
                onClick={() => goMonth(month.add(1, 'month'))}
              >
                <RightOutlined />
              </button>
            </div>
          </header>

          <div className="cal-weekdays">
            {WEEKDAYS.map((d) => (
              <span key={d}>{d}</span>
            ))}
          </div>

          <Spin spinning={isLoading}>
            <div className="cal-grid">
              {cells.map((date, i) => {
                if (!date) return <span key={`blank-${i}`} className="cal-day is-blank" />
                const key = date.format('YYYY-MM-DD')
                const items = byDate.get(key) ?? []
                const classes = [
                  'cal-day',
                  date.day() === 0 && 'is-sunday',
                  date.isSame(selected, 'day') && 'is-selected',
                  date.isSame(today, 'day') && 'is-today',
                ]
                  .filter(Boolean)
                  .join(' ')
                const cell = (
                  <button
                    key={key}
                    type="button"
                    className={classes}
                    aria-pressed={date.isSame(selected, 'day')}
                    aria-label={`${thaiDate(date)} ${items.length} รายการ`}
                    data-testid={`calendar-day-${date.date()}`}
                    onClick={() => setSelected(date)}
                  >
                    <span className="cal-day__num">{date.date()}</span>
                    {items.length > 0 && (
                      <i className="cal-day__dot" data-testid="calendar-badge" />
                    )}
                  </button>
                )
                return items.length > 0 ? (
                  <Popover
                    key={key}
                    content={<DayTooltip items={items} />}
                    arrow={false}
                    mouseEnterDelay={0.4}
                    placement="rightTop"
                    classNames={{ root: 'cal-tip' }}
                  >
                    {cell}
                  </Popover>
                ) : (
                  cell
                )
              })}
            </div>
          </Spin>
        </section>

        <aside className="cal-agenda" data-testid="calendar-agenda">
          <header className="cal-agenda__head">
            <div>
              <h2>รายละเอียดวันนี้</h2>
              <p>{thaiDate(selected)}</p>
            </div>
            <span className="cal-count" data-testid="calendar-agenda-count">
              {agenda.length} รายการ
            </span>
          </header>

          <div className="cal-agenda__list">
            {agenda.length === 0 ? (
              <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="ไม่มีรายการในวันนี้" />
            ) : (
              agenda.map((item) => (
                <article key={item.id} className="cal-card" data-testid="calendar-agenda-item">
                  <div className="cal-card__top">
                    <div className="cal-card__title">
                      <strong>
                        {item.equipmentName}
                        {item.quantity > 1 && ` ×${item.quantity}`}
                      </strong>
                      <span>{timeRange(item)}</span>
                    </div>
                    <StatusLabel status={item.status} />
                  </div>
                  <hr className="cal-card__line" />
                  <div className="cal-card__bottom">
                    <Requester item={item} />
                    <StatusChip status={item.status} />
                  </div>
                </article>
              ))
            )}
          </div>
        </aside>
      </div>
    </div>
  )
}
