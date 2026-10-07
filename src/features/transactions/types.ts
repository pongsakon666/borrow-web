export type TransactionType = 'borrow' | 'return'

export type TransactionStatus = 'pending' | 'approved' | 'in_progress' | 'complete' | 'rejected'

export const TRANSACTION_STATUS_LABEL: Record<TransactionStatus, string> = {
  pending: 'Pending',
  approved: 'Approved',
  in_progress: 'In Progress',
  complete: 'Complete',
  rejected: 'Rejected',
}

export const TRANSACTION_TYPE_LABEL: Record<TransactionType, string> = {
  borrow: 'ยืม',
  return: 'คืน',
}

export interface Transaction {
  id: string
  code: string
  type: TransactionType
  status: TransactionStatus
  equipmentId: string
  equipmentName: string
  equipmentCode: string
  userId: string
  userName: string
  quantity: number
  occurredAt: string
  dueAt: string | null
  returnedAt: string | null
  note: string
}

export interface CreateTransactionInput {
  type: TransactionType
  equipmentId: string
  quantity?: number
  dueAt?: string
  note?: string
}
