import { useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/app/store/auth.store'
import { getErrorMessage } from '@/shared/api/http'
import { authApi } from '../api/auth.api'
import type { LoginRequest } from '../types/auth.types'

export function useLogin() {
  const navigate = useNavigate()
  const setSession = useAuthStore((s) => s.setSession)

  const mutation = useMutation({
    mutationFn: (payload: LoginRequest) => authApi.login(payload),
    onSuccess: ({ accessToken, user }) => {
      setSession(accessToken, user)
      navigate('/', { replace: true })
    },
  })

  return {
    login: mutation.mutate,
    isPending: mutation.isPending,
    errorMessage: mutation.isError ? getErrorMessage(mutation.error, 'เข้าสู่ระบบไม่สำเร็จ') : null,
    reset: mutation.reset,
  }
}
