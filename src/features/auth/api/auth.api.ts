import { http } from '@/shared/api/http'
import type { LoginRequest, LoginResponse, UserProfile } from '../types/auth.types'

export const authApi = {
  async login(payload: LoginRequest): Promise<LoginResponse> {
    const { data } = await http.post<LoginResponse>('/auth/login', payload)
    return data
  },

  async me(): Promise<UserProfile> {
    const { data } = await http.get<UserProfile>('/auth/me')
    return data
  },

  async logout(): Promise<void> {
    await http.post('/auth/logout')
  },
}
