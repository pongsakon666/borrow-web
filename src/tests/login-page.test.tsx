import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient } from '@tanstack/react-query'
import { AppProviders } from '@/app/providers'
import { LoginPage } from '@/features/auth/pages/login-page'

function renderLogin() {
  return render(
    <AppProviders client={new QueryClient()}>
      <MemoryRouter initialEntries={['/login']}>
        <LoginPage />
      </MemoryRouter>
    </AppProviders>,
  )
}

describe('LoginPage', () => {
  it('แสดงฟอร์มเข้าสู่ระบบ', () => {
    renderLogin()
    expect(screen.getByTestId('login-title')).toHaveTextContent('เข้าสู่ระบบ')
    expect(screen.getByTestId('login-email')).toBeInTheDocument()
    expect(screen.getByTestId('login-password')).toBeInTheDocument()
  })

  it('กดส่งโดยไม่กรอก → ขึ้น error ใต้ช่องกรอก', async () => {
    renderLogin()
    await userEvent.click(screen.getByTestId('login-submit'))
    expect(await screen.findByText('กรุณากรอกอีเมล')).toBeInTheDocument()
    expect(await screen.findByText('กรุณากรอกรหัสผ่าน')).toBeInTheDocument()
  })
})
