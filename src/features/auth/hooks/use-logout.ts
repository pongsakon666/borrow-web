import { useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/app/store/auth.store'
import { authApi } from '../api/auth.api'

export function useLogout() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const clear = useAuthStore((s) => s.clear)

  return async () => {
    // รอ API ไม่เกิน 3 วินาที — ช้าหรือล้มเหลวก็ต้องเคลียร์ session ฝั่ง client อยู่ดี
    await Promise.race([
      authApi.logout().catch(() => undefined),
      new Promise((resolve) => setTimeout(resolve, 3000)),
    ])
    clear()
    queryClient.clear()
    navigate('/login', { replace: true })
  }
}
