import '../borrow.css'
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { App, Button, Empty, Input, Modal, Pagination, Select, Table } from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  FilterOutlined,
  PlusOutlined,
  SearchOutlined,
  TableOutlined,
  UnorderedListOutlined,
} from '@ant-design/icons'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import dayjs from 'dayjs'
import { getErrorMessage } from '@/shared/api/http'
import { formatDate } from '@/shared/utils/format'
import { ConfirmModal } from '@/shared/components/confirm-modal'
import { PageHeader } from '@/shared/components/page-header'
import { SectionCard } from '@/shared/components/section-card'
import { StatCard } from '@/shared/components/stat-card'
import { StatusPill } from '@/shared/components/status-pill'
import { UserAvatar } from '@/shared/components/user-avatar'
import { transactionsApi } from '../api'
import { TRANSACTION_STATUS_LABEL, type Transaction, type TransactionStatus } from '../types'
import { BORROW_STATUS, formatClock, isWalkIn, parseBorrowNote } from '../borrow-meta'

const PAGE_SIZE = 10

/** ตัวกรองสถานะ — title เป็นชื่ออังกฤษเดิม (Robot เลือก option ด้วย title) */
const STATUS_OPTIONS = [
  { value: '', label: 'ทุกสถานะ', title: 'ทุกสถานะ' },
  ...(Object.keys(TRANSACTION_STATUS_LABEL) as TransactionStatus[]).map((value) => ({
    value,
    title: TRANSACTION_STATUS_LABEL[value],
    label:
      value === 'pending'
        ? 'รอรับของ (รออนุมัติ)'
        : value === 'approved'
          ? 'รอรับของ (อนุมัติแล้ว)'
          : BORROW_STATUS[value].label,
  })),
]

/** ปุ่มหลักในคอลัมน์ "การจัดการ" ตามสถานะ */
const NEXT_ACTION: Partial<Record<TransactionStatus, { label: string; next: TransactionStatus; testId: string }>> = {
  pending: { label: 'จ่ายอุปกรณ์', next: 'in_progress', testId: 'tx-issue' },
  approved: { label: 'จ่ายอุปกรณ์', next: 'in_progress', testId: 'tx-issue' },
  in_progress: { label: 'คืนอุปกรณ์', next: 'complete', testId: 'tx-return' },
}

type ViewMode = 'table' | 'list'

/**
 * หน้า "รายการยืมวันนี้" — ตารางจองล่วงหน้า + Walk-in
 * selector สำหรับ Robot: transactions-page / tx-search / tx-status / tx-table (ครอบทั้งสองตาราง)
 */
export function BorrowPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { message } = App.useApp()
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [views, setViews] = useState<Record<'booking' | 'walkin', ViewMode>>({
    booking: 'table',
    walkin: 'table',
  })
  const [pendingAction, setPendingAction] = useState<{ tx: Transaction; next: TransactionStatus } | null>(null)
  const [detail, setDetail] = useState<Transaction | null>(null)

  const today = useMemo(() => dayjs(), [])

  const list = useQuery({
    queryKey: ['transactions', 'borrow', search, status, page],
    queryFn: () =>
      transactionsApi.list({
        type: 'borrow',
        search: search || undefined,
        status: status || undefined,
        page,
        limit: PAGE_SIZE,
      }),
    refetchInterval: 30_000,
  })

  // สถิติของวันนี้ — ดึงทั้งวันแล้วนับฝั่ง client
  // API จำกัด limit สูงสุด 100 → ถ้าวันนี้มีเกิน 100 รายการต้องดึงหน้าที่เหลือด้วย ไม่งั้นยอด Walk-in/จอง/จ่ายแล้วจะนับไม่ครบ
  const todayQuery = useQuery({
    queryKey: ['transactions', 'borrow', 'today', today.format('YYYY-MM-DD')],
    queryFn: async () => {
      const query = {
        type: 'borrow',
        from: today.startOf('day').toISOString(),
        to: today.endOf('day').toISOString(),
        limit: 100,
      }
      const first = await transactionsApi.list({ ...query, page: 1 })
      const pages = Math.ceil(first.total / first.limit)
      const rest = await Promise.all(
        Array.from({ length: Math.max(pages - 1, 0) }, (_, i) => transactionsApi.list({ ...query, page: i + 2 })),
      )
      return { ...first, items: [first, ...rest].flatMap((res) => res.items) }
    },
    refetchInterval: 30_000,
  })

  const stats = useMemo(() => {
    const items = todayQuery.data?.items ?? []
    const walkIn = items.filter(isWalkIn).length
    return {
      total: todayQuery.data?.total ?? 0,
      booking: items.length - walkIn,
      walkIn,
      issued: items.filter((tx) => tx.status === 'in_progress' || tx.status === 'complete').length,
    }
  }, [todayQuery.data])

  const rows = list.data?.items ?? []
  const bookingRows = rows.filter((tx) => !isWalkIn(tx))
  const walkInRows = rows.filter(isWalkIn)

  const changeStatus = useMutation({
    mutationFn: ({ id, next }: { id: string; next: TransactionStatus }) =>
      transactionsApi.updateStatus(id, next),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['transactions'] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      message.success('อัปเดตสถานะแล้ว')
      setPendingAction(null)
    },
    onError: (error) => message.error(getErrorMessage(error, 'อัปเดตสถานะไม่สำเร็จ')),
  })

  const columns = (walkIn: boolean): ColumnsType<Transaction> => [
    {
      title: walkIn ? 'เวลาเข้ายืม' : 'เวลาจอง',
      dataIndex: 'occurredAt',
      width: 112,
      render: (value: string) => (
        <div className="borrow-cell-time">
          <strong>{formatClock(value)}</strong>
          {!dayjs(value).isSame(today, 'day') && <small>{dayjs(value).format('DD/MM/YYYY')}</small>}
        </div>
      ),
    },
    {
      title: 'ผู้ใช้บริการ',
      key: 'user',
      render: (_, row) => {
        const note = parseBorrowNote(row.note)
        const name = note.booker || row.userName
        return (
          <div className="cell-person">
            <UserAvatar name={name} size={40} />
            <div className="cell-person__text">
              <small>{[row.code, note.department].filter(Boolean).join(' · ')}</small>
              <strong>{name}</strong>
            </div>
          </div>
        )
      },
    },
    {
      title: walkIn ? 'อุปกรณ์ที่ยืม' : 'อุปกรณ์ที่จอง',
      dataIndex: 'equipmentName',
      render: (value: string, row) => (
        <div className="borrow-cell-equipment">
          <strong>{value}</strong>
          {row.dueAt && <small>กำหนดคืน {formatDate(row.dueAt)}</small>}
        </div>
      ),
    },
    {
      title: 'จำนวน',
      dataIndex: 'quantity',
      width: 116,
      render: (value: number) => `${value} ชิ้น`,
    },
    {
      title: walkIn ? 'สถานะอุปกรณ์' : 'สถานะการจอง',
      dataIndex: 'status',
      width: 136,
      render: (value: TransactionStatus) => <BorrowStatus status={value} />,
    },
    {
      title: 'การจัดการ',
      key: 'actions',
      width: 136,
      align: 'center',
      render: (_, row) => renderAction(row),
    },
  ]

  const renderAction = (row: Transaction) => {
    const action = NEXT_ACTION[row.status]
    if (action) {
      return (
        <Button
          className="row-action is-ghost"
          data-testid={action.testId}
          onClick={() => setPendingAction({ tx: row, next: action.next })}
        >
          {action.label}
        </Button>
      )
    }
    return (
      <Button className="row-action" data-testid="tx-detail" onClick={() => setDetail(row)}>
        ดูรายละเอียด
      </Button>
    )
  }

  const renderSection = (key: 'booking' | 'walkin', data: Transaction[]) => {
    const walkIn = key === 'walkin'
    const view = views[key]
    const toggle = (mode: ViewMode) => setViews((prev) => ({ ...prev, [key]: mode }))

    return (
      <SectionCard
        accent
        title={walkIn ? 'รายการผู้ขอยืม Walk-in' : 'รายการจองล่วงหน้า'}
        badge={`${walkIn ? stats.walkIn : stats.booking} รายการวันนี้`}
        badgeTone={walkIn ? 'pink' : 'purple'}
        className={`borrow-section is-${key}`}
        testId={`borrow-${key}`}
        extra={
          <>
            <button
              type="button"
              className={`borrow-view-btn${view === 'table' ? ' is-active' : ''}`}
              aria-label="มุมมองตาราง"
              onClick={() => toggle('table')}
            >
              <TableOutlined />
            </button>
            <button
              type="button"
              className={`borrow-view-btn${view === 'list' ? ' is-active' : ''}`}
              aria-label="มุมมองรายการ"
              onClick={() => toggle('list')}
            >
              <UnorderedListOutlined />
            </button>
          </>
        }
      >
        {view === 'table' ? (
          <Table<Transaction>
            className="data-table"
            rowKey="id"
            loading={list.isLoading}
            dataSource={data}
            columns={columns(walkIn)}
            pagination={false}
            scroll={{ x: 900 }}
            locale={{ emptyText: <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="ไม่มีรายการ" /> }}
          />
        ) : data.length ? (
          <ul className="borrow-list">
            {data.map((row) => {
              const note = parseBorrowNote(row.note)
              return (
                <li key={row.id} className="borrow-list__item">
                  <span className="borrow-list__time">{formatClock(row.occurredAt)}</span>
                  <UserAvatar name={note.booker || row.userName} size={32} />
                  <div className="borrow-list__text">
                    <strong>{row.equipmentName}</strong>
                    <small>
                      {note.booker || row.userName} · {row.quantity} ชิ้น
                    </small>
                  </div>
                  <BorrowStatus status={row.status} />
                  {renderAction(row)}
                </li>
              )
            })}
          </ul>
        ) : (
          <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="ไม่มีรายการ" />
        )}
      </SectionCard>
    )
  }

  const detailNote = parseBorrowNote(detail?.note)

  return (
    <div className="page borrow-page" data-testid="transactions-page">
      <PageHeader
        title="รายการยืมวันนี้"
        subtitle={`จัดการและตรวจสอบรายการจ่ายเครื่องมือและอุปกรณ์ประจำวันที่ ${today.format('MM/DD/YYYY')}`}
        testId="borrow-header"
        actions={
          <>
            <span data-testid="tx-search" className="borrow-search">
              <Input
                className="toolbar-search"
                allowClear
                prefix={<SearchOutlined />}
                placeholder="ค้นหารายการ ชื่อ หรืออุปกรณ์..."
                onPressEnter={(e) => {
                  setSearch(e.currentTarget.value.trim())
                  setPage(1)
                }}
                onChange={(e) => {
                  // ล้างด้วยปุ่ม x → แสดงทั้งหมด
                  if (!e.target.value && search) {
                    setSearch('')
                    setPage(1)
                  }
                }}
              />
            </span>
            <Select
              data-testid="tx-status"
              className="borrow-filter"
              value={status}
              prefix={<FilterOutlined />}
              options={STATUS_OPTIONS}
              popupMatchSelectWidth={false}
              labelRender={(option) => (option.value ? option.label : 'ตัวกรองขั้นสูง')}
              onChange={(value: string) => {
                setStatus(value)
                setPage(1)
              }}
            />
            <Button
              className="btn-sky borrow-add"
              icon={<PlusOutlined />}
              data-testid="borrow-add"
              onClick={() => navigate('/borrow/new')}
            >
              เพิ่มรายการ
            </Button>
          </>
        }
      />

      <div className="stat-row">
        <StatCard
          tint="lavender"
          label="รายการวันนี้ทั้งหมด"
          value={`${stats.total} รายการ`}
          hint="อัปเดตเรียลไทม์"
          hintBadge
          testId="borrow-stat-total"
        />
        <StatCard tint="sky" label="จองล่วงหน้า" value={`${stats.booking} รายการ`} hint="มารับตามเวลา" testId="borrow-stat-booking" />
        <StatCard tint="lavender" label="Walk-in" value={`${stats.walkIn} รายการ`} hint="หน้าเคาน์เตอร์" testId="borrow-stat-walkin" />
        <StatCard tint="sky" label="อุปกรณ์ถูกจ่ายแล้ว" value={`${stats.issued} รายการ`} hint="จากผู้ยืมทั้งหมด" testId="borrow-stat-issued" />
      </div>

      <div className="borrow-sections" data-testid="tx-table">
        {renderSection('booking', bookingRows)}
        {renderSection('walkin', walkInRows)}
      </div>

      <Pagination
        className="borrow-pagination"
        current={page}
        pageSize={list.data?.limit ?? PAGE_SIZE}
        total={list.data?.total ?? 0}
        onChange={setPage}
        showSizeChanger={false}
        hideOnSinglePage
        showTotal={(total) => `ทั้งหมด ${total} รายการ`}
      />

      <ConfirmModal
        open={Boolean(pendingAction)}
        title={pendingAction?.next === 'complete' ? 'ยืนยันการรับคืนอุปกรณ์ ?' : 'ยืนยันการจ่ายอุปกรณ์ ?'}
        description={
          pendingAction
            ? `${pendingAction.tx.equipmentName} × ${pendingAction.tx.quantity}\nโปรดตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยัน`
            : undefined
        }
        loading={changeStatus.isPending}
        onOk={() => pendingAction && changeStatus.mutate({ id: pendingAction.tx.id, next: pendingAction.next })}
        onCancel={() => setPendingAction(null)}
        testId="tx-action-confirm"
      />

      <Modal
        open={Boolean(detail)}
        onCancel={() => setDetail(null)}
        footer={null}
        width={480}
        centered
        title="รายละเอียดรายการ"
        className="borrow-detail"
        destroyOnHidden
      >
        {detail && (
          <dl className="borrow-detail__list" data-testid="tx-detail-modal">
            <dt>รหัสรายการ</dt>
            <dd>{detail.code}</dd>
            <dt>ผู้ใช้บริการ</dt>
            <dd>{detailNote.booker || detail.userName}</dd>
            {detailNote.phone && (
              <>
                <dt>เบอร์โทร</dt>
                <dd>{detailNote.phone}</dd>
              </>
            )}
            {detailNote.department && (
              <>
                <dt>หน่วยงาน</dt>
                <dd>{detailNote.department}</dd>
              </>
            )}
            <dt>อุปกรณ์</dt>
            <dd>
              {detail.equipmentName} ({detail.equipmentCode}) × {detail.quantity}
            </dd>
            <dt>สถานะ</dt>
            <dd>
              <BorrowStatus status={detail.status} />
            </dd>
            <dt>วันที่บันทึก</dt>
            <dd>
              {formatDate(detail.occurredAt)} {formatClock(detail.occurredAt)}
            </dd>
            <dt>กำหนดคืน</dt>
            <dd>{formatDate(detail.dueAt)}</dd>
            {detail.returnedAt && (
              <>
                <dt>วันที่คืน</dt>
                <dd>{formatDate(detail.returnedAt)}</dd>
              </>
            )}
            {detailNote.channel && (
              <>
                <dt>ช่องทาง</dt>
                <dd>{detailNote.channel}</dd>
              </>
            )}
            {(detailNote.details || detailNote.remark) && (
              <>
                <dt>หมายเหตุ</dt>
                <dd className="is-multiline">
                  {[detailNote.details, detailNote.remark].filter(Boolean).join('\n')}
                </dd>
              </>
            )}
          </dl>
        )}
      </Modal>
    </div>
  )
}

/** pill สถานะ + ชื่ออังกฤษซ่อนไว้ (Robot ตรวจข้อความ "Complete" ในแถว) */
function BorrowStatus({ status }: { status: TransactionStatus }) {
  const meta = BORROW_STATUS[status]
  return (
    <StatusPill tone={meta.tone} testId={`status-${status}`}>
      {meta.label}
      <span className="sr-only">{TRANSACTION_STATUS_LABEL[status]}</span>
    </StatusPill>
  )
}
