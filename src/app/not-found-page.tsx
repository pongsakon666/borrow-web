import { Button } from 'antd'
import { useNavigate } from 'react-router-dom'

/** หน้า 404 — path ที่ไม่มีใน router (อยู่ใน shell เพราะผ่าน guard แล้ว) */
export function NotFoundPage() {
  const navigate = useNavigate()

  return (
    <div className="not-found" data-testid="not-found-page">
      <strong className="not-found__code">404</strong>
      <h1 className="not-found__title">ไม่พบหน้าที่ต้องการ</h1>
      <p className="not-found__desc">ลิงก์อาจไม่ถูกต้อง หรือหน้านี้ถูกย้ายไปแล้ว</p>
      <Button type="primary" shape="round" onClick={() => navigate('/')} data-testid="not-found-home">
        กลับหน้า Dashboard
      </Button>
    </div>
  )
}
