import { http } from '@/shared/api/http'
import type { Equipment, EquipmentInput, Paginated } from '../types/equipment.types'

export interface EquipmentQuery {
  search?: string
  category?: string
  status?: string
  page?: number
  limit?: number
}

export const equipmentApi = {
  async list(query: EquipmentQuery = {}): Promise<Paginated<Equipment>> {
    const { data } = await http.get<Paginated<Equipment>>('/equipment', { params: query })
    return data
  },

  async categories(): Promise<string[]> {
    const { data } = await http.get<string[]>('/equipment/categories')
    return data
  },

  async get(id: string): Promise<Equipment> {
    const { data } = await http.get<Equipment>(`/equipment/${id}`)
    return data
  },

  async create(input: EquipmentInput): Promise<Equipment> {
    const { data } = await http.post<Equipment>('/equipment', input)
    return data
  },

  async update(id: string, input: Partial<EquipmentInput>): Promise<Equipment> {
    const { data } = await http.patch<Equipment>(`/equipment/${id}`, input)
    return data
  },

  async remove(id: string): Promise<void> {
    await http.delete(`/equipment/${id}`)
  },
}
