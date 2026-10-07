import { create } from 'zustand'
import type { UserProfile } from '@/features/auth/types/auth.types'

/**
 * Auth state (client-side) — access token เก็บใน memory + sessionStorage (README §8.4)
 * refresh token เป็น httpOnly cookie ฝั่ง BE (FE อ่านไม่ได้ ส่งไปกับ withCredentials)
 */
const TOKEN_KEY = 'access_token'
const USER_KEY = 'auth_user'

function readStoredUser(): UserProfile | null {
  try {
    const raw = sessionStorage.getItem(USER_KEY)
    return raw ? (JSON.parse(raw) as UserProfile) : null
  } catch {
    return null
  }
}

interface AuthState {
  accessToken: string | null
  user: UserProfile | null
  isAuthenticated: boolean
  setSession: (token: string, user: UserProfile) => void
  setAccessToken: (token: string | null) => void
  clear: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  accessToken: sessionStorage.getItem(TOKEN_KEY),
  user: readStoredUser(),
  isAuthenticated: Boolean(sessionStorage.getItem(TOKEN_KEY)),

  setSession: (token, user) => {
    sessionStorage.setItem(TOKEN_KEY, token)
    sessionStorage.setItem(USER_KEY, JSON.stringify(user))
    set({ accessToken: token, user, isAuthenticated: true })
  },

  setAccessToken: (token) => {
    if (token) sessionStorage.setItem(TOKEN_KEY, token)
    else sessionStorage.removeItem(TOKEN_KEY)
    set({ accessToken: token, isAuthenticated: Boolean(token) })
  },

  clear: () => {
    sessionStorage.removeItem(TOKEN_KEY)
    sessionStorage.removeItem(USER_KEY)
    set({ accessToken: null, user: null, isAuthenticated: false })
  },
}))
