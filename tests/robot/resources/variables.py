"""ตัวแปรกลางของ Robot suite — อ่านจาก env เพื่อให้รันได้ทั้ง local / CI"""

import os

BASE_URL = os.getenv("E2E_BASE_URL", "http://localhost:5173")
API_URL = os.getenv("E2E_API_URL", "http://localhost:3001")

# บัญชีตัวอย่างที่ UsersSeeder สร้างให้ตอน API start
# (rent-borrow-api/src/modules/users/users.seeder.ts)
USER = os.getenv("E2E_USER", "admin@example.com")
PASSWORD = os.getenv("E2E_PASSWORD", "Passw0rd!")
USER_NAME = os.getenv("E2E_USER_NAME", "ผู้ดูแลระบบ")

HEADLESS = os.getenv("E2E_HEADLESS", "true").lower() == "true"

# หน่วงทุก action ของ browser (เช่น "500ms") — ใช้คู่กับ -Headed เพื่อดูการทำงานช้า ๆ
SLOW_MO = os.getenv("E2E_SLOWMO", "0ms")

# ข้อมูลตัวอย่างจาก DemoSeeder — ใช้ยืนยันว่าหน้าจอผูกกับ API จริง
SEED_EQUIPMENT_NAME = "เครื่องปริ้นเตอร์ Laser MX-300"
SEED_EQUIPMENT_CODE = "RQ-100-OFF-3000"
SEED_CATEGORY = "อุปกรณ์สำนักงาน"
SEED_MEMBER = "Natali Craig"
