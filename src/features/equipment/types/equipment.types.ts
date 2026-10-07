export type EquipmentStatus = 'ready' | 'borrowed' | 'maintenance' | 'retired'

export const EQUIPMENT_STATUS_LABEL: Record<EquipmentStatus, string> = {
  ready: 'พร้อมใช้งาน',
  borrowed: 'ถูกยืมอยู่',
  maintenance: 'ซ่อมบำรุง',
  retired: 'ปลดระวาง',
}

export interface Equipment {
  id: string
  code: string
  name: string
  category: string
  department: string
  price: number
  unit: string
  quantity: number
  borrowedQuantity: number
  status: EquipmentStatus
  description: string
  images: string[]
  purchasedAt: string | null
  isDraft: boolean
  createdAt: string
  updatedAt: string
}

export interface EquipmentInput {
  code: string
  name: string
  category: string
  department?: string
  price?: number
  unit?: string
  quantity?: number
  status?: EquipmentStatus
  description?: string
  images?: string[]
  purchasedAt?: string
  isDraft?: boolean
}

export interface Paginated<T> {
  items: T[]
  total: number
  page: number
  limit: number
}
