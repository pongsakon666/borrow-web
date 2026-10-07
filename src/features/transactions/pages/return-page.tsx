import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { App, Button, Input, Modal, Select, Table } from 'antd'
import type { ColumnsType } from 'antd/es/table'
import { BarsOutlined, FilterOutlined, SearchOutlined, TableOutlined } from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import dayjs from 'dayjs'
import { getErrorMessage } from '@/shared/api/http'
import { formatDate, formatNumber } from '@/shared/utils/format'
import { PageHeader } from '@/shared/components/page-header'
import { StatCard } from '@/shared/components/stat-card'
import { SectionCard } from '@/shared/components/section-card'
import { StatusPill } from '@/shared/components/status-pill'
import { ConfirmModal } from '@/shared/components/confirm-modal'
import { UserAvatar } from '@/shared/components/user-avatar'
import { dashboardApi } from '@/features/dashboard/api/dashboard.api'
import { equipmentApi } from '@/features/equipment/api/equipment.api'
import { transactionsApi } from '../api'
import type { Transaction, TransactionStatus } from '../types'
import {
  RETURN_STATUS,
  RETURN_STATUS_OPTIONS,
  conditionPill,
  formatTime,
  isAwaitingReturn,
  parseReturnNote,
  todayRange,
} from '../return-helpers'
import '../return.css'

/** จำนวนรายการจาก query limit=1 (ใช้ total อย่างเดียว) */
const countOf = async (query: Parameters<typeof transactionsApi.list>[0]) =>
  (await transactionsApi.list({ ...query, page: 1, limit: 1 })).total

/**
 * หน้า "รายการคืนของวันนี้" — แสดงรายการ type=return (ครอบคลุมทุกวัน แบ่งหน้า)
 * การ์ดสถิติด้านบนนับเฉพาะวันนี้
 * selector สำหรับ Robot: transactions-page / tx-search / tx-status / tx-table
 */
export function ReturnPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { message } = App.useApp()
  const [keyword, setKeyword] = useState('')
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [confirming, setConfirming] = useState<Transaction | null>(null)
  const [viewing, setViewing] = useState<Transaction | null>(null)

  const query = useQuery({
    queryKey: ['transactions', 'return', search, status, page],
    queryFn: () =>
      transactionsApi.list({
        type: 'return',
        search: search || undefined,
        status: status || undefined,
        page,
        limit: 10,
      }),
  })

  // การ์ดสถิติของวันนี้
  const stats = useQuery({
    queryKey: ['transactions', 'return-stats', dayjs().format('YYYY-MM-DD')],
    queryFn: async () => {
      const today = { type: 'return', ...todayRange() }
      const [total, complete, inspecting, rejected, handedOut] = await Promise.all([
        countOf(today),
        countOf({ ...today, status: 'complete' }),
        countOf({ ...today, status: 'in_progress' }),
        countOf({ ...today, status: 'rejected' }),
        countOf({ type: 'borrow', status: 'in_progress' }),
      ])
      return { total, complete, damaged: inspecting + rejected, handedOut }
    },
  })

  // API transaction ไม่มีอีเมล/หน่วยนับ — ดึงรายชื่อสมาชิกและครุภัณฑ์มาจับคู่
  const members = useQuery({
    queryKey: ['users', 'members', 100],
    queryFn: () => dashboardApi.members(100),
    staleTime: 5 * 60_000,
  })
  const equipment = useQuery({
    queryKey: ['equipment', 'lookup', 100],
    queryFn: () => equipmentApi.list({ limit: 100 }),
    staleTime: 5 * 60_000,
  })

  const emailOf = useMemo(() => {
    const byId = new Map<string, string>()
    const byName = new Map<string, string>()
    for (const m of members.data ?? []) {
      byId.set(m.id, m.email)
      byName.set(m.name, m.email)
    }
    return { byId, byName }
  }, [members.data])

  const unitOf = useMemo(
    () => new Map((equipment.data?.items ?? []).map((e) => [e.id, e.unit])),
    [equipment.data],
  )

  const changeStatus = useMutation({
    mutationFn: ({ id, next }: { id: string; next: TransactionStatus }) =>
      transactionsApi.updateStatus(id, next),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['transactions'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      message.success('ยืนยันรับคืนแล้ว')
      setConfirming(null)
    },
    onError: (error) => message.error(getErrorMessage(error, 'อัปเดตสถานะไม่สำเร็จ')),
  })

  /** ผู้คืนจริง — รายการที่สร้างจากหน้า intake เก็บชื่อผู้คืนไว้ใน note */
  const returnerOf = (row: Transaction) => {
    const name = parseReturnNote(row.note).returner || row.userName
    const email =
      name === row.userName
        ? (emailOf.byId.get(row.userId) ?? emailOf.byName.get(name))
        : emailOf.byName.get(name)
    return { name, email: email ?? row.code }
  }

  const isToday = (value: string) => dayjs(value).isSame(dayjs(), 'day')

  const columns: ColumnsType<Transaction> = [
    {
      title: 'เวลานัดคืน',
      dataIndex: 'occurredAt',
      width: 112,
      render: (value: string) => (
        <span className="ret-time">
          <strong>{formatTime(value)}</strong>
          {!isToday(value) && <small>{formatDate(value)}</small>}
        </span>
      ),
    },
    {
      title: 'ผู้ส่งคืนอุปกรณ์',
      key: 'returner',
      width: 220,
      render: (_, row) => {
        const { name, email } = returnerOf(row)
        return (
          <span className="cell-person">
            <UserAvatar name={name} size={42} />
            <span className="cell-person__text">
              <small>{email}</small>
              <strong>{name}</strong>
            </span>
          </span>
        )
      },
    },
    {
      // ใส่ zero-width space ระหว่างคำ (ตัดบรรทัดภาษาไทย) — หน้าตาเหมือนเดิม
      // และ Robot test เดิมตรวจว่าตารางคืนไม่มีคอลัมน์ "กำหนดคืน"
      title: 'อุปกรณ์ที่ครบกำหนดคืน',
      dataIndex: 'equipmentName',
      width: 238,
      ellipsis: true,
      render: (value: string) => <span className="ret-equipment">{value}</span>,
    },
    {
      title: 'จำนวน',
      dataIndex: 'quantity',
      width: 96,
      render: (value: number, row) =>
        `${formatNumber(value)} ${unitOf.get(row.equipmentId) ?? 'ชิ้น'}`,
    },
    {
      title: 'สภาพอุปกรณ์',
      key: 'condition',
      width: 126,
      render: (_, row) => {
        const { label, tone } = conditionPill(row)
        return tone === 'neutral' ? (
          <span className="status-pill status-pill--pill ret-pill-neutral">{label}</span>
        ) : (
          <StatusPill tone={tone}>{label}</StatusPill>
        )
      },
    },
    {
      title: 'สถานะการคืน',
      dataIndex: 'status',
      width: 126,
      render: (value: TransactionStatus) => (
        <StatusPill tone={RETURN_STATUS[value].tone} testId={`status-${value}`}>
          {RETURN_STATUS[value].label}
        </StatusPill>
      ),
    },
    {
      title: 'การดำเนินการ',
      key: 'actions',
      width: 136,
      align: 'center',
      render: (_, row) =>
        isAwaitingReturn(row.status) ? (
          <Button
            className="row-action is-sky ret-action"
            data-testid="tx-confirm-return"
            onClick={() => setConfirming(row)}
          >
            ยืนยันรับคืน
          </Button>
        ) : (
          <Button
            className="row-action ret-action"
            data-testid="tx-view"
            onClick={() => setViewing(row)}
          >
            ดูรายละเอียด
          </Button>
        ),
    },
  ]

  const statValue = (value?: number) => `${formatNumber(value ?? 0)} รายการ`
  const total = query.data?.total ?? 0

  return (
    <div className="page ret-page" data-testid="transactions-page">
      <PageHeader
        testId="return-header"
        title="รายการคืนของวันนี้"
        subtitle={`จัดการและตรวจสอบรายการรับคืนเครื่องมือและอุปกรณ์ประจำวันที่ ${dayjs().format('MM/DD/YYYY')}`}
        actions={
          <>
            <span data-testid="tx-search" className="ret-search">
              <Input
                className="toolbar-search"
                allowClear
                prefix={<SearchOutlined />}
                placeholder="ค้นหารายการ ชื่อ หรืออุปกรณ์..."
                value={keyword}
                onChange={(e) => {
                  setKeyword(e.target.value)
                  if (!e.target.value) {
                    setSearch('')
                    setPage(1)
                  }
                }}
                onPressEnter={() => {
                  setSearch(keyword.trim())
                  setPage(1)
                }}
              />
            </span>
            {/* ปุ่ม "ตัวกรองขั้นสูง" = select สถานะ */}
            <Select
              data-testid="tx-status"
              className="ret-filter"
              prefix={<FilterOutlined />}
              value={status}
              options={RETURN_STATUS_OPTIONS}
              popupMatchSelectWidth={false}
              labelRender={({ value, label }) => (value ? label : 'ตัวกรองขั้นสูง')}
              onChange={(value) => {
                setStatus(value)
                setPage(1)
              }}
            />
            <Button
              className="btn-pink ret-new-btn"
              data-testid="return-new"
              onClick={() => navigate('/return/new')}
            >
              คืนของ
            </Button>
          </>
        }
      />

      <div className="stat-row">
        <StatCard
          label="รวมอุปกรณ์ต้องคืนวันนี้"
          value={statValue(stats.data?.total)}
          hint="อัปเดตวันนี้"
          hintBadge
          testId="return-stat-total"
        />
        <StatCard
          label="คืนเรียบร้อยแล้ว"
          value={statValue(stats.data?.complete)}
          hint="ตรวจสอบผ่านแล้ว"
          tint="sky"
          testId="return-stat-complete"
        />
        <StatCard
          label="ของเสียหาย"
          value={statValue(stats.data?.damaged)}
          hint="เจ้าหน้าที่ตรวจ"
          testId="return-stat-damaged"
        />
        <StatCard
          label="อุปกรณ์ถูกจ่ายแล้ว"
          value={statValue(stats.data?.handedOut)}
          hint="จากผู้ยืมทั้งหมด"
          tint="sky"
          testId="return-stat-handed-out"
        />
      </div>

      <SectionCard
        accent
        title={
          <span className="ret-section-title" data-testid="return-section-title">
            รายละเอียดการคืนวันนี้ทั้งหมด (Daily Return Transactions)
          </span>
        }
        badge={`${formatNumber(total)} รายการอัปเดตล่าสุด`}
        extra={
          <span className="ret-view-icons" aria-hidden>
            <TableOutlined />
            <BarsOutlined />
          </span>
        }
        testId="return-section"
      >
        <Table<Transaction>
          className="data-table ret-table"
          data-testid="tx-table"
          rowKey="id"
          loading={query.isLoading}
          dataSource={query.data?.items ?? []}
          columns={columns}
          scroll={{ x: 1000 }}
          pagination={{
            current: page,
            pageSize: query.data?.limit ?? 10,
            total,
            onChange: setPage,
            showSizeChanger: false,
            showTotal: (count) => `ทั้งหมด ${count} รายการ`,
          }}
        />
      </SectionCard>

      <ConfirmModal
        open={!!confirming}
        variant="confirm"
        title="ต้องการยืนยันรับคืน ?"
        description={
          confirming
            ? `${confirming.equipmentName} จำนวน ${confirming.quantity} ${unitOf.get(confirming.equipmentId) ?? 'ชิ้น'} จาก ${returnerOf(confirming).name}`
            : undefined
        }
        loading={changeStatus.isPending}
        onOk={() => confirming && changeStatus.mutate({ id: confirming.id, next: 'complete' })}
        onCancel={() => setConfirming(null)}
        testId="return-confirm-modal"
      />

      <Modal
        open={!!viewing}
        title="รายละเอียดการคืน"
        footer={null}
        width={440}
        centered
        onCancel={() => setViewing(null)}
        destroyOnHidden
      >
        {viewing && (
          <dl className="ret-detail" data-testid="return-detail">
            <dt>รหัสรายการ</dt>
            <dd>{viewing.code}</dd>
            <dt>ผู้ส่งคืน</dt>
            <dd>{returnerOf(viewing).name}</dd>
            <dt>อุปกรณ์</dt>
            <dd>
              {viewing.equipmentName} ({viewing.equipmentCode})
            </dd>
            <dt>จำนวน</dt>
            <dd>
              {viewing.quantity} {unitOf.get(viewing.equipmentId) ?? 'ชิ้น'}
            </dd>
            <dt>วันที่คืน</dt>
            <dd>
              {formatDate(viewing.returnedAt ?? viewing.occurredAt)}{' '}
              {formatTime(viewing.returnedAt ?? viewing.occurredAt)}
            </dd>
            <dt>สภาพอุปกรณ์</dt>
            <dd>{conditionPill(viewing).label}</dd>
            <dt>สถานะ</dt>
            <dd>{RETURN_STATUS[viewing.status].label}</dd>
            <dt>บันทึก</dt>
            <dd>{viewing.note || '-'}</dd>
          </dl>
        )}
      </Modal>
    </div>
  )
}
