import { http } from '@/shared/api/http'
import type { Transaction } from '@/features/transactions/types'
import type { UserProfile } from '@/features/auth/types/auth.types'

export type DashboardRange = 'today' | 'week' | 'month' | 'year'

export interface SummaryCard {
  key: 'total' | 'borrowed' | 'returned' | 'available'
  label: string
  value: number
  change: number
}

export interface DashboardSummary {
  cards: SummaryCard[]
  usage: { month: string; current: number; previous: number }[]
  popular: { name: string; value: number }[]
  yearly: { month: string; value: number }[]
  recent: Transaction[]
}

export interface Activity {
  id: string
  kind: string
  actorName: string
  message: string
  isNotification: boolean
  isRead: boolean
  createdAt: string
}

export const dashboardApi = {
  async summary(range: DashboardRange = 'month'): Promise<DashboardSummary> {
    const { data } = await http.get<DashboardSummary>('/dashboard/summary', { params: { range } })
    return data
  },

  async activities(limit = 6): Promise<Activity[]> {
    const { data } = await http.get<Activity[]>('/activities', { params: { limit } })
    return data
  },

  async notifications(limit = 6): Promise<{ items: Activity[]; unread: number }> {
    const { data } = await http.get<{ items: Activity[]; unread: number }>('/notifications', {
      params: { limit },
    })
    return data
  },

  async members(limit = 6): Promise<UserProfile[]> {
    const { data } = await http.get<UserProfile[]>('/users', { params: { limit } })
    return data
  },
}
