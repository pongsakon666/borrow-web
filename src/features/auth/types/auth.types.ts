export type UserRole = 'admin' | 'staff' | 'user'

export interface UserProfile {
  id: string
  email: string
  name: string
  role: UserRole
}

export interface LoginRequest {
  email: string
  password: string
}

export interface LoginResponse {
  accessToken: string
  user: UserProfile
}
