import { useMemo, useState, type ReactNode } from 'react'
import { App, Button, DatePicker, Dropdown, Input, Select, Table } from 'antd'
import {
  CalendarOutlined,
  DownOutlined,
  FilterOutlined,
  LineChartOutlined,
  PlusOutlined,
  WarningOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import {
  Bar,
  BarChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { formatNumber } from '@/shared/utils/format'
import { PageHeader } from '@/shared/components/page-header'
import { transactionsApi } from '@/features/transactions/api'
import type { Transaction } from '@/features/transactions/types'
import { equipmentApi } from '../api/equipment.api'
import type { Equipment, EquipmentStatus } from '../types/equipment.types'
import '../reports.css'

const { RangePicker } = DatePicker

/** สีกราฟตามดีไซน์ — ยืม = คราม · คืน = เขียว */
const BORROW_COLOR = '#424f9b'
const RETURN_COLOR = '#50cd89'

/** สัดส่วนสถานะ: ready=ว่าง · borrowed=ยืมอยู่ · retired=เสียหาย · maintenance=ซ่อมแซม */
const STATUS_SLICES: { key: EquipmentStatus; label: string; color: string }[] = [
  { key: 'ready', label: 'ว่าง (พร้อมใช้)', color: '#50cd89' },
  { key: 'borrowed', label: 'ยืมอยู่', color: '#424f9b' },
  { key: 'retired', label: 'เสียหาย', color: '#ef4444' },
  { key: 'maintenance', label: 'ซ่อมแซม', color: '#f97316' },
]

/** pill สถานะในตาราง (สีตามดีไซน์ Recent Items) */
const PILL = {
  sky: { bg: '#e0f2fe', fg: '#0284c7' },
  green: { bg: '#dcfce7', fg: '#15803d' },
  red: { bg: '#fee2e2', fg: '#b91c1c' },
  orange: { bg: '#ffedd5', fg: '#c2410c' },
  gray: { bg: '#f1f1f1', fg: '#6b7280' },
} as const

const STATUS_FILTER: { value: string; label: string }[] = [
  { value: '', label: 'ทุกสถานะ' },
  { value: 'ready', label: 'ว่าง (พร้อมใช้)' },
  { value: 'borrowed', label: 'ยืมอยู่' },
  { value: 'maintenance', label: 'ซ่อมแซม' },
  { value: 'retired', label: 'เสียหาย' },
]

/** 12 มิ.ย. 66 */
const shortThai = (value?: string | null) => {
  if (!value) return '-'
  const d = dayjs(value)
  return `${d.locale('th').format('DD MMM')} ${String((d.year() + 543) % 100).padStart(2, '0')}`
}

/** 1 มิ.ย. 2566 */
const longThai = (d: Dayjs) => `${d.locale('th').format('D MMM')} ${d.year() + 543}`

const percentChange = (current: number, previous: number) =>
  previous === 0 ? (current > 0 ? 100 : 0) : Math.round(((current - previous) / previous) * 100)

const signed = (value: number) => `${value > 0 ? '+' : ''}${value}`

/** ป้ายสถานะของแถว — ดูสถานะครุภัณฑ์ + รายการยืมล่าสุด */
function rowStatus(
  row: Equipment,
  latest?: Transaction,
): { label: string; tone: keyof typeof PILL } {
  switch (row.status) {
    case 'borrowed': {
      const overdue = latest?.dueAt && !latest.returnedAt && dayjs(latest.dueAt).isBefore(dayjs())
      return overdue ? { label: 'เกินกำหนด', tone: 'orange' } : { label: 'ยืมอยู่', tone: 'sky' }
    }
    case 'maintenance':
      return { label: 'ซ่อมแซม', tone: 'orange' }
    case 'retired':
      return { label: 'เสียหาย', tone: 'red' }
    default:
      return latest?.returnedAt
        ? { label: 'คืนแล้ว', tone: 'green' }
        : { label: 'ว่าง', tone: 'gray' }
  }
}

interface KpiProps {
  label: string
  value: number
  change: ReactNode
  note: string
  danger?: boolean
  testId: string
}

/** การ์ด KPI พื้นขาว + ไอคอนสี่เหลี่ยมเล็กมุมขวา */
function KpiCard({ label, value, change, note, danger = false, testId }: KpiProps) {
  return (
    <div className="rp-kpi" data-testid={testId}>
      <div className="rp-kpi__head">
        <span>{label}</span>
        <i className={`rp-kpi__icon ${danger ? 'is-red' : 'is-green'}`}>
          {danger ? <WarningOutlined /> : <LineChartOutlined />}
        </i>
      </div>
      <div className="rp-kpi__body">
        <strong data-testid={`${testId}-value`}>{formatNumber(value)}</strong>
        <div className="rp-kpi__foot">
          {change}
          <span>{note}</span>
        </div>
      </div>
    </div>
  )
}

function Change({ value, suffix }: { value: number; suffix: string }) {
  return (
    <b className={value < 0 ? 'is-down' : 'is-up'}>
      {signed(value)}% {suffix}
    </b>
  )
}

/**
 * Product Report — สรุปยืม-คืน + สัดส่วนสถานะ + ตารางครุภัณฑ์ (Recent Items)
 * selector สำหรับ Robot: data-testid = equipment-list-page / eq-search / eq-category / eq-table / eq-add
 */
export function EquipmentListPage() {
  const { message } = App.useApp()
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [range, setRange] = useState<[Dayjs, Dayjs]>(() => [
    dayjs().startOf('month'),
    dayjs().endOf('month'),
  ])

  const { data: categories = [] } = useQuery({
    queryKey: ['equipment', 'categories'],
    queryFn: () => equipmentApi.categories(),
  })

  const query = useQuery({
    queryKey: ['equipment', 'list', search, category, status, page],
    queryFn: () =>
      equipmentApi.list({
        search: search || undefined,
        category: category || undefined,
        status: status || undefined,
        page,
        limit: 10,
      }),
  })

  // จำนวนครุภัณฑ์แยกตามสถานะ (ใช้ total ของแต่ละสถานะ)
  const statusCounts = useQuery({
    queryKey: ['equipment', 'status-counts'],
    queryFn: async () => {
      const totals = await Promise.all(
        STATUS_SLICES.map((s) =>
          equipmentApi.list({ status: s.key, limit: 1 }).then((r) => r.total),
        ),
      )
      return Object.fromEntries(STATUS_SLICES.map((s, i) => [s.key, totals[i]])) as Record<
        EquipmentStatus,
        number
      >
    },
  })

  // ยืม/คืนในช่วงที่เลือก เทียบช่วงก่อนหน้าที่ยาวเท่ากัน
  const [from, to] = range
  const rangeCounts = useQuery({
    queryKey: ['transactions', 'report-range', from.toISOString(), to.toISOString()],
    queryFn: async () => {
      const span = to.diff(from)
      const prevFrom = from.subtract(span, 'millisecond')
      const count = (type: string, a: Dayjs, b: Dayjs) =>
        transactionsApi
          .list({ type, from: a.toISOString(), to: b.toISOString(), limit: 1 })
          .then((r) => r.total)
      const [borrow, ret, prevBorrow, prevReturn] = await Promise.all([
        count('borrow', from, to),
        count('return', from, to),
        count('borrow', prevFrom, from),
        count('return', prevFrom, from),
      ])
      return { borrow, ret, prevBorrow, prevReturn }
    },
  })

  // กราฟรายเดือน 6 เดือนย้อนหลังนับจากเดือนสิ้นสุดของช่วง
  const monthly = useQuery({
    queryKey: ['transactions', 'report-monthly', to.format('YYYY-MM')],
    queryFn: async () => {
      const months = Array.from({ length: 6 }, (_, i) =>
        to.startOf('month').subtract(5 - i, 'month'),
      )
      const count = (type: string, m: Dayjs) =>
        transactionsApi
          .list({
            type,
            from: m.startOf('month').toISOString(),
            to: m.endOf('month').toISOString(),
            limit: 1,
          })
          .then((r) => r.total)
      return Promise.all(
        months.map(async (m) => {
          const [borrow, ret] = await Promise.all([count('borrow', m), count('return', m)])
          return { month: m.locale('th').format('MMM'), borrow, return: ret }
        }),
      )
    },
  })

  // รายการยืมล่าสุด → ผู้ยืม/วันที่ของแต่ละครุภัณฑ์
  const latest = useQuery({
    queryKey: ['transactions', 'report-latest'],
    queryFn: () => transactionsApi.list({ type: 'borrow', limit: 100 }),
  })

  const latestByEquipment = useMemo(() => {
    const map = new Map<string, Transaction>()
    for (const item of latest.data?.items ?? []) {
      if (!map.has(item.equipmentId)) map.set(item.equipmentId, item)
    }
    return map
  }, [latest.data])

  const counts = statusCounts.data
  const totalItems = counts ? Object.values(counts).reduce((a, b) => a + b, 0) : 0
  const readyPct = totalItems && counts ? Math.round((counts.ready / totalItems) * 100) : 0
  const rc = rangeCounts.data
  const chartData = monthly.data ?? []
  const chartMax = Math.max(4, ...chartData.flatMap((d) => [d.borrow, d.return]))
  const yMax = Math.ceil(chartMax / 2) * 2

  const columns: ColumnsType<Equipment> = [
    {
      title: 'รหัสสินค้า',
      dataIndex: 'code',
      width: 170,
      render: (value: string) => <span className="rp-code">{value}</span>,
    },
    {
      title: 'ชื่อสินค้า',
      dataIndex: 'name',
      ellipsis: true,
      render: (value: string) => <span className="rp-name">{value}</span>,
    },
    { title: 'ประเภท', dataIndex: 'category', width: 160, ellipsis: true },
    {
      title: 'สถานะ',
      dataIndex: 'status',
      width: 120,
      render: (value: EquipmentStatus, row) => {
        const { label, tone } = rowStatus(row, latestByEquipment.get(row.id))
        return (
          <span
            className="rp-pill"
            style={{ background: PILL[tone].bg, color: PILL[tone].fg }}
            data-testid={`eq-status-${value}`}
          >
            {label}
          </span>
        )
      },
    },
    {
      title: 'ผู้ยืม',
      key: 'borrower',
      width: 160,
      ellipsis: true,
      render: (_, row) => latestByEquipment.get(row.id)?.userName ?? '-',
    },
    {
      title: 'วันที่ยืม',
      key: 'borrowedAt',
      width: 120,
      render: (_, row) => (
        <span className="rp-date">{shortThai(latestByEquipment.get(row.id)?.occurredAt)}</span>
      ),
    },
    {
      title: 'วันที่คืน',
      key: 'returnedAt',
      width: 120,
      render: (_, row) => {
        const tx = latestByEquipment.get(row.id)
        return <span className="rp-date">{shortThai(tx?.returnedAt ?? tx?.dueAt)}</span>
      },
    },
  ]

  // ส่งออกแถวที่แสดงในตารางเป็น CSV (ฝั่ง client)
  const exportCsv = () => {
    const rows = query.data?.items ?? []
    if (rows.length === 0) {
      message.warning('ไม่มีข้อมูลให้ส่งออก')
      return
    }
    const header = [
      'รหัสสินค้า',
      'ชื่อสินค้า',
      'ประเภท',
      'สถานะ',
      'ผู้ยืม',
      'วันที่ยืม',
      'วันที่คืน',
    ]
    const lines = rows.map((row) => {
      const tx = latestByEquipment.get(row.id)
      return [
        row.code,
        row.name,
        row.category,
        rowStatus(row, tx).label,
        tx?.userName ?? '-',
        tx ? dayjs(tx.occurredAt).format('YYYY-MM-DD') : '-',
        tx?.returnedAt || tx?.dueAt ? dayjs(tx.returnedAt ?? tx.dueAt).format('YYYY-MM-DD') : '-',
      ]
    })
    const csv = [header, ...lines]
      .map((cols) => cols.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(','))
      .join('\r\n')
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `product-report-${dayjs().format('YYYYMMDD')}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  const statusLabel = STATUS_FILTER.find((s) => s.value === status)?.label

  return (
    <div className="page rp-page" data-testid="equipment-list-page">
      <PageHeader
        title="รายงานการยืมคืน (Product Report)"
        subtitle="สถิติการทำรายการยืม-คืน และรายงานสรุปสินค้าชำรุดเสียหาย"
        actions={
          <>
            <RangePicker
              className="rp-range"
              data-testid="report-range"
              value={range}
              allowClear={false}
              inputReadOnly
              prefix={<CalendarOutlined />}
              suffixIcon={<DownOutlined />}
              separator="-"
              format={(d) => longThai(d)}
              onChange={(values) => {
                if (values?.[0] && values[1]) {
                  setRange([values[0].startOf('day'), values[1].endOf('day')])
                }
              }}
            />
            <Button
              type="primary"
              className="rp-export"
              data-testid="report-export"
              onClick={exportCsv}
            >
              ส่งออกรายงาน (Export)
            </Button>
          </>
        }
      />

      <div className="rp-kpis">
        <KpiCard
          testId="report-total"
          label="สินค้าทั้งหมด"
          value={totalItems}
          change={<b className="is-up">{readyPct}% พร้อมใช้</b>}
          note="รายการ"
        />
        <KpiCard
          testId="report-borrowed"
          label="ยืมทั้งหมด"
          value={rc?.borrow ?? 0}
          change={
            <Change
              value={percentChange(rc?.borrow ?? 0, rc?.prevBorrow ?? 0)}
              suffix="จากช่วงก่อน"
            />
          }
          note="รายการ"
        />
        <KpiCard
          testId="report-returned"
          label="คืนแล้ว"
          value={rc?.ret ?? 0}
          change={
            <Change value={percentChange(rc?.ret ?? 0, rc?.prevReturn ?? 0)} suffix="จากช่วงก่อน" />
          }
          note="รายการ"
        />
        <KpiCard
          testId="report-damaged"
          label="เสียหาย"
          danger
          value={counts?.retired ?? 0}
          change={<b className="is-down">+{counts?.maintenance ?? 0} รายการซ่อมแซม</b>}
          note="สถานะปัจจุบัน"
        />
      </div>

      <div className="rp-charts">
        <section className="rp-card rp-trend" data-testid="report-trend">
          <header className="rp-card__head">
            <div>
              <h2>การยืม-คืน</h2>
              <p>เปรียบเทียบจำนวนการทำรายการยืมและคืนรายเดือน</p>
            </div>
            <div className="rp-legend-inline">
              <span>
                <i style={{ background: BORROW_COLOR }} />
                ยืม
              </span>
              <span>
                <i style={{ background: RETURN_COLOR }} />
                คืน
              </span>
            </div>
          </header>
          <ResponsiveContainer width="100%" height={170}>
            <BarChart
              data={chartData}
              margin={{ top: 6, right: 0, left: -28, bottom: 0 }}
              barGap={4}
            >
              <XAxis
                dataKey="month"
                tick={{ fontSize: 12, fill: '#64748b' }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                domain={[0, yMax]}
                ticks={[0, yMax / 2, yMax]}
                tick={{ fontSize: 10, fill: '#64748b' }}
                axisLine={false}
                tickLine={false}
                allowDecimals={false}
              />
              <Tooltip
                cursor={{ fill: '#f7f8fa' }}
                formatter={(value, name) => [
                  formatNumber(Number(value ?? 0)),
                  name === 'borrow' ? 'ยืม' : 'คืน',
                ]}
              />
              <Bar dataKey="borrow" fill={BORROW_COLOR} barSize={16} radius={[4, 4, 0, 0]} />
              <Bar dataKey="return" fill={RETURN_COLOR} barSize={16} radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </section>

        <section className="rp-card rp-donut" data-testid="report-status">
          <header className="rp-card__head">
            <div>
              <h2>สัดส่วนสถานะ</h2>
              <p>แบ่งตามสภาพและการใช้งานปัจจุบัน</p>
            </div>
          </header>
          <div className="rp-donut__body">
            <div className="rp-donut__chart">
              <ResponsiveContainer width={120} height={120}>
                <PieChart>
                  <Pie
                    data={
                      totalItems
                        ? STATUS_SLICES.map((s) => ({ name: s.label, value: counts?.[s.key] ?? 0 }))
                        : [{ name: 'ไม่มีข้อมูล', value: 1 }]
                    }
                    dataKey="value"
                    innerRadius={44}
                    outerRadius={60}
                    startAngle={90}
                    endAngle={-270}
                    stroke="#fff"
                    strokeWidth={2}
                    isAnimationActive={false}
                  >
                    {totalItems ? (
                      STATUS_SLICES.map((s) => <Cell key={s.key} fill={s.color} />)
                    ) : (
                      <Cell fill="#e2e8f0" />
                    )}
                  </Pie>
                  {totalItems > 0 && (
                    <Tooltip formatter={(value) => formatNumber(Number(value ?? 0))} />
                  )}
                </PieChart>
              </ResponsiveContainer>
              <div className="rp-donut__center">
                <small>ทั้งหมด</small>
                <strong>{formatNumber(totalItems)}</strong>
                <small>รายการ</small>
              </div>
            </div>
            <ul className="rp-legend">
              {STATUS_SLICES.map((s) => (
                <li key={s.key}>
                  <span>
                    <i style={{ background: s.color }} />
                    {s.label}
                  </span>
                  <b>{formatNumber(counts?.[s.key] ?? 0)}</b>
                </li>
              ))}
            </ul>
          </div>
        </section>
      </div>

      <section className="rp-card rp-table-card">
        <header className="rp-card__head">
          <div>
            <h2>รายการล่าสุด (Recent Items)</h2>
            <p>สถานะและกิจกรรมล่าสุดของการทำรายการยืม-คืนเครื่องมือและอุปกรณ์</p>
          </div>
          <div className="rp-tools">
            <Input.Search
              className="rp-search"
              data-testid="eq-search"
              allowClear
              placeholder="ค้นหาชื่อ / รหัสสินค้า"
              onSearch={(value) => {
                setSearch(value)
                setPage(1)
              }}
            />
            <Select
              className="rp-select"
              data-testid="eq-category"
              value={category}
              popupMatchSelectWidth={false}
              options={[
                { value: '', label: 'ทุกประเภท' },
                ...categories.map((c) => ({ value: c, label: c })),
              ]}
              onChange={(value) => {
                setCategory(value)
                setPage(1)
              }}
            />
            <Dropdown
              trigger={['click']}
              menu={{
                selectable: true,
                selectedKeys: [status || 'all'],
                items: STATUS_FILTER.map((s) => ({ key: s.value || 'all', label: s.label })),
                onClick: ({ key }) => {
                  setStatus(key === 'all' ? '' : key)
                  setPage(1)
                },
              }}
            >
              <button
                type="button"
                className={`rp-filter${status ? ' is-active' : ''}`}
                data-testid="eq-status-filter"
              >
                <FilterOutlined />
                {status ? statusLabel : 'กรองตาราง'}
              </button>
            </Dropdown>
            <Link to="/equipment/new">
              <Button className="rp-add" icon={<PlusOutlined />} data-testid="eq-add">
                เพิ่มสินค้า
              </Button>
            </Link>
          </div>
        </header>

        <Table<Equipment>
          className="data-table rp-table"
          data-testid="eq-table"
          rowKey="id"
          loading={query.isLoading}
          dataSource={query.data?.items ?? []}
          columns={columns}
          scroll={{ x: 900 }}
          pagination={{
            current: page,
            pageSize: query.data?.limit ?? 10,
            total: query.data?.total ?? 0,
            onChange: setPage,
            showSizeChanger: false,
            showTotal: (total) => `ทั้งหมด ${total} รายการ`,
          }}
        />
      </section>
    </div>
  )
}
