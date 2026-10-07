import { Alert, Button, Divider, Form, Input, Typography } from 'antd'
import { GoogleOutlined } from '@ant-design/icons'
import { Link, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/app/store/auth.store'
import { WaveArt } from '../components/wave-art'
import { useLogin } from '../hooks/use-login'
import type { LoginRequest } from '../types/auth.types'

const { Title, Text } = Typography

/**
 * หน้าเข้าสู่ระบบ — ซ้ายเป็นภาพประกอบ ขวาเป็นฟอร์ม (จอเล็กเหลือเฉพาะฟอร์ม)
 * selector สำหรับ Robot: data-testid = login-title / login-email / login-password /
 *                                     login-submit / login-error / login-google / login-register
 */
export function LoginPage() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const { login, isPending, errorMessage } = useLogin()

  if (isAuthenticated) return <Navigate to="/" replace />

  return (
    <div className="auth-shell">
      <aside className="auth-visual" aria-hidden="true">
        <WaveArt />
      </aside>

      <main className="auth-panel">
        <div className="auth-card">
          <header className="auth-card__header">
            <Title level={2} data-testid="login-title" className="auth-card__title">
              เข้าสู่ระบบ
            </Title>
            <Text className="auth-card__subtitle">ระบบยืม-คืนครุภัณฑ์</Text>
          </header>

          {errorMessage && (
            <Alert
              data-testid="login-error"
              type="error"
              showIcon
              message={errorMessage}
              className="auth-card__alert"
            />
          )}

          <Form<LoginRequest>
            data-testid="login-form"
            layout="vertical"
            requiredMark={false}
            initialValues={{ email: '', password: '' }}
            onFinish={({ email, password }) => login({ email, password })}
            disabled={isPending}
          >
            <Form.Item
              label="Email"
              name="email"
              rules={[
                { required: true, message: 'กรุณากรอกอีเมล' },
                { type: 'email', message: 'รูปแบบอีเมลไม่ถูกต้อง' },
              ]}
            >
              <Input data-testid="login-email" name="email" autoComplete="username" placeholder="กรอกข้อมูล" />
            </Form.Item>

            <Form.Item
              label="Password"
              name="password"
              rules={[{ required: true, message: 'กรุณากรอกรหัสผ่าน' }]}
              className="auth-card__password"
            >
              <Input.Password
                data-testid="login-password"
                name="password"
                autoComplete="current-password"
                placeholder="กรอกข้อมูล"
              />
            </Form.Item>

            <div className="auth-card__forgot">
              <Link to="/forgot-password" data-testid="login-forgot">
                ลืมรหัสผ่าน
              </Link>
            </div>

            <Button
              data-testid="login-submit"
              type="primary"
              htmlType="submit"
              block
              loading={isPending}
              className="auth-card__submit"
            >
              เข้าสู่ระบบ
            </Button>
          </Form>

          <Divider plain className="auth-card__divider">
            Or
          </Divider>

          <Button
            data-testid="login-google"
            block
            icon={<GoogleOutlined className="auth-card__google-icon" />}
            className="auth-card__google"
            onClick={() => window.alert('ยังไม่ได้เชื่อมต่อ Google OAuth')}
          >
            Sign in with Google
          </Button>

          <p className="auth-card__register">
            ยังไม่มีบัญชี?{' '}
            <Link to="/register" data-testid="login-register">
              สมัครสมาชิก
            </Link>
          </p>

          <footer className="auth-card__foot">Riverpark</footer>
        </div>
      </main>
    </div>
  )
}
