import axios, { AxiosError, type AxiosRequestConfig, type InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '@/app/store/auth.store'

/**
 * axios instance กลาง (README §2, §8.4)
 * - แนบ Bearer token จาก auth store
 * - แนบ x-correlation-id ทุก request (ตรงกับ BE logger)
 * - 401 → refresh token ได้ "ครั้งเดียว" ต่อ request และ queue request อื่นที่ 401 พร้อมกัน
 *   ไม่ให้ยิง refresh ซ้อน / logout รัว ๆ
 */
export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api/v1',
  timeout: 15_000,
  withCredentials: true, // ให้ refresh token (httpOnly cookie) ติดไปด้วย
})

type RetriableConfig = InternalAxiosRequestConfig & { _retry?: boolean }

// ── request: token + correlation id ───────────────────────────────────
http.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken
  if (token) config.headers.Authorization = `Bearer ${token}`
  if (!config.headers['x-correlation-id']) config.headers['x-correlation-id'] = crypto.randomUUID()
  return config
})

// ── response: refresh-once + queue ────────────────────────────────────
let refreshing: Promise<string | null> | null = null

async function refreshAccessToken(): Promise<string | null> {
  try {
    // endpoint นี้ยังไม่มีใน BE — ปรับ path ตอนทำ auth module
    const { data } = await axios.post<{ accessToken: string }>(
      `${http.defaults.baseURL}/auth/refresh`,
      null,
      { withCredentials: true },
    )
    useAuthStore.getState().setAccessToken(data.accessToken)
    return data.accessToken
  } catch {
    useAuthStore.getState().clear()
    return null
  }
}

http.interceptors.response.use(
  (res) => res,
  async (err: AxiosError) => {
    const original = err.config as RetriableConfig | undefined
    if (!original || err.response?.status !== 401 || original._retry) {
      return Promise.reject(err)
    }
    if (original.url?.includes('/auth/refresh') || original.url?.includes('/auth/login')) {
      return Promise.reject(err)
    }

    original._retry = true
    refreshing ??= refreshAccessToken().finally(() => {
      refreshing = null
    })

    const token = await refreshing
    if (!token) return Promise.reject(err)

    original.headers.Authorization = `Bearer ${token}`
    return http(original as AxiosRequestConfig)
  },
)

/** แปลง error ของ axios เป็นข้อความสั้น ๆ ไว้โชว์ใน UI */
export function getErrorMessage(err: unknown, fallback = 'เกิดข้อผิดพลาด'): string {
  if (axios.isAxiosError(err)) {
    const data = err.response?.data as { message?: string | string[] } | undefined
    const msg = data?.message
    if (Array.isArray(msg)) return msg.join(', ')
    if (typeof msg === 'string') return msg
    return err.message || fallback
  }
  return err instanceof Error ? err.message : fallback
}
