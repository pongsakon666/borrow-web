"""เตรียมข้อมูลการแจ้งเตือนสำหรับ E2E

ฝั่ง BE ไม่มี endpoint สร้างการแจ้งเตือน (มีเฉพาะจาก DemoSeeder ตอนเริ่มระบบ 2 รายการ)
เมื่อกด "อ่านทั้งหมด" ไปแล้วครั้งหนึ่ง unread จะเป็น 0 ตลอด → เทสต์รันซ้ำไม่ได้
จึงเขียนแถวลงตาราง activities ของ SQLite (dev DB) ตรง ๆ แล้วลบทิ้งตอน teardown

ตั้ง path เองได้ด้วย env E2E_SQLITE_PATH
ค่า default = <drive>/rent-borrow-api/.data/dev.sqlite (repo API วางคู่กับ repo web)
"""

import os
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path

from robot.api.deco import keyword, library


def _default_db_path() -> Path:
    # resources/libs/NotificationSeed.py → parents[5] = โฟลเดอร์ที่มี rent-borrow-web
    return Path(__file__).resolve().parents[5] / "rent-borrow-api" / ".data" / "dev.sqlite"


@library(scope="GLOBAL")
class NotificationSeed:
    def __init__(self):
        self.db_path = Path(os.getenv("E2E_SQLITE_PATH") or _default_db_path())

    def _connect(self) -> sqlite3.Connection:
        if not self.db_path.exists():
            raise AssertionError(f"ไม่พบไฟล์ SQLite ของ API: {self.db_path} (ตั้ง E2E_SQLITE_PATH)")
        return sqlite3.connect(str(self.db_path), timeout=10)

    @keyword("Seed Unread Notification")
    def seed_unread_notification(self, message: str, actor: str = "Robot E2E") -> str:
        """เพิ่มการแจ้งเตือนที่ยังไม่อ่าน 1 รายการ คืนค่า id ไว้ลบตอนจบ"""
        new_id = str(uuid.uuid4())
        # TypeORM (better-sqlite3) เก็บ datetime เป็น UTC รูปแบบ 'YYYY-MM-DD HH:MM:SS.fff'
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        with self._connect() as conn:
            conn.execute(
                'INSERT INTO activities (id, kind, "actorName", message, "isNotification", "isRead", created_at)'
                " VALUES (?, 'system', ?, ?, 1, 0, ?)",
                (new_id, actor, message, now),
            )
        return new_id

    @keyword("Delete Notification")
    def delete_notification(self, notification_id: str) -> None:
        with self._connect() as conn:
            conn.execute("DELETE FROM activities WHERE id = ?", (notification_id,))
