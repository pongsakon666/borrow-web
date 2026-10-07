import { http } from '@/shared/api/http'
import type { Paginated } from '@/features/equipment/types/equipment.types'
import type { CreateTransactionInput, Transaction, TransactionStatus } from './types'

export interface TransactionQuery {
  type?: string
  status?: string
  search?: string
  from?: string
  to?: string
  page?: number
  limit?: number
}

export const transactionsApi = {
  async list(query: TransactionQuery = {}): Promise<Paginated<Transaction>> {
    const { data } = await http.get<Paginated<Transaction>>('/transactions', { params: query })
    return data
  },

  async create(input: CreateTransactionInput): Promise<Transaction> {
    const { data } = await http.post<Transaction>('/transactions', input)
    return data
  },

  async updateStatus(id: string, status: TransactionStatus): Promise<Transaction> {
    const { data } = await http.patch<Transaction>(`/transactions/${id}/status`, { status })
    return data
  },
}
