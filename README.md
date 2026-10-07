# rent-borrow-web

Frontend ของระบบยืม-เช่า — **React 19 · TypeScript · Vite · axios · TanStack Query · zustand · antd**
อิงจาก stack ใน `D:\new\README.md` (§2, §3, §8.4)

> สถานะ: ครบ 8 หน้า — Login · Dashboard · Add Products (wizard) · Borrow · Return · Calendar · Reports Product · Notifications · Settings

## โครงสร้าง

```
src/
├── main.tsx / App.tsx        → entry · AppProviders + AppRouter
├── app/
│   ├── providers.tsx         → QueryClientProvider · antd ConfigProvider (th_TH + theme)
│   ├── theme.ts              → design token กลาง: BRAND / STATUS_COLOR / CHART_COLORS / antdTheme
│   ├── query-client.ts       → default options (staleTime, retry เฉพาะ 5xx)
│   ├── router.tsx            → /login (public) · ที่เหลืออยู่หลัง RequireAuth
│   ├── guards/require-auth   → ยังไม่ล็อกอิน → เด้งไป /login
│   ├── layouts/
│   │   ├── menu-items.tsx    → นิยามเมนู (key = path) ใช้ร่วมกันระหว่าง sidebar กับ header
│   │   ├── app-sidebar.tsx   → เมนูซ้าย · ย่อ/ขยายได้ · ชื่อผู้ใช้ด้านล่าง
│   │   ├── app-header.tsx    → ชื่อหน้า · กระดิ่งแจ้งเตือน · EN|TH · เมนูผู้ใช้ (ออกจากระบบ)
│   │   └── root-layout.tsx   → ประกอบ sidebar + header + Outlet
│   └── store/auth.store.ts   → zustand: access token + user profile (sessionStorage)
├── features/
│   ├── auth/                 → api · hooks (use-login, use-logout) · pages/login-page
│   ├── dashboard/            → api · components/dashboard-charts (recharts) · pages (dashboard, calendar, notifications)
│   ├── equipment/            → api · types · pages (equipment-form wizard, equipment-list)
│   ├── transactions/         → api · types · pages/transactions-page (ใช้ร่วมกัน borrow/return)
│   └── settings/             → pages/settings-page
├── shared/
│   ├── api/http.ts           → axios instance: Bearer · x-correlation-id · refresh-once + queue
│   ├── components/           → brand-logo
│   └── utils/format.ts       → formatNumber/Currency/Date/Relative/Change · avatarColor
└── tests/                    → vitest setup + smoke/login test
tests/robot/                  → Robot Framework E2E — แยกนอก src
```

## เริ่มต้น

```bash
cp .env.example .env
npm install
npm run dev              # http://localhost:5173 · /api → proxy ไป http://localhost:3001
```

## Scripts

| คำสั่ง | ทำอะไร |
|---|---|
| `npm run dev` | Vite dev server (proxy `/api` → BE :3001) |
| `npm run build` | `tsc -b && vite build` → `dist/` |
| `npm run test` / `test:watch` / `test:cov` | vitest (jsdom + Testing Library) |
| `npm run lint` / `format` / `typecheck` | eslint / prettier / tsc |
| `npm run gen:api` | gen type จาก Swagger ของ BE → `src/shared/api/schema.d.ts` (BE ต้องรันอยู่) |

## E2E — Robot Framework

```powershell
cd tests\robot
.\run-e2e.ps1 -DryRun            # เช็ค syntax (ไม่ต้องมี FE/BE)
.\run-e2e.ps1 -Tag ui            # UI smoke — ต้องมี FE รันอยู่ (npm run dev)
.\run-e2e.ps1 -Tag ui -Headed    # ดู browser ทำงานจริง
.\run-e2e.ps1 -Tag api           # API — ต้องมี BE :3001 (และ infra)
.\run-e2e.ps1                    # ทั้งหมด → เปิด results\report.html อัตโนมัติ
```

script จะสร้าง `.venv` + `pip install` + `rfbrowser init` ให้เองถ้ายังไม่มี · หรือทำมือ:

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
rfbrowser init chromium                     # ครั้งแรก (โหลด Playwright browser)
robot -d results -i smoke suites
```

ตัวแปร: `E2E_BASE_URL` `E2E_API_URL` `E2E_USER` `E2E_PASSWORD` `E2E_HEADLESS` (ดู `resources/variables.py`)

## กติกาที่ตั้งไว้แล้ว

- Path alias `@/` → `src/`
- access token อยู่ใน zustand + `sessionStorage` · refresh token คาดว่าเป็น httpOnly cookie (axios `withCredentials: true`)
- 401 → refresh ได้ครั้งเดียวต่อ request และ queue request ที่ 401 พร้อมกันรวมกันเป็น refresh เดียว
- ทุก request แนบ `x-correlation-id` ให้ตรงกับ BE logger
- `refreshAccessToken()` ชี้ไป `/auth/refresh` ของ BE (ทำแล้ว)

## หน้า login — selector สำหรับ Robot

ทุก element ที่เทสต์ต้องจับมี `data-testid` เพื่อไม่ให้ test พังเวลาแก้ CSS/ข้อความ

| data-testid | element |
|---|---|
| `login-title` `login-email` `login-password` `login-submit` `login-google` `login-forgot` `login-register` | หน้าเข้าสู่ระบบ |
| `login-error` | alert ตอน login ไม่ผ่าน (มาจาก API) |
| `app-sidebar` `sidebar-toggle` `sidebar-user` `nav-*` | เมนูซ้าย (`nav-dashboard`, `nav-equipment-new`, `nav-borrow`, …) |
| `page-title` `header-bell` `header-user-menu` `header-user` `logout-button` | header |
| `dashboard-page` `dashboard-range` `stat-grid` `stat-{key}-value` | Dashboard — การ์ดสรุป |
| `popular-list` `recent-table` `rail-notifications` `rail-activities` `rail-members` | Dashboard — กราฟ/ตาราง/แถบขวา |
| `equipment-form-page` `wizard-step-{1..3}` `wizard-panel-*` `field-*` `review-*` `wizard-next/back/submit/draft/progress` | wizard เพิ่มครุภัณฑ์ |
| `equipment-list-page` `eq-table` `eq-search` `eq-category` `eq-add` | Reports Product |
| `transactions-page` `tx-table` `tx-search` `tx-status` `tx-approve` `tx-reject` | Borrow / Return |
| `calendar-page` `notifications-page` `settings-page` | หน้าอื่น ๆ |

> error ของแต่ละช่องกรอกเป็นของ antd — ใช้ `.ant-form-item-explain-error` (ดู `login_page.resource`)

## ขั้นต่อไป (ยังไม่เริ่ม)

1. **อัปโหลดรูปจริง** — ขั้น "สื่อประกอบ" ของ wizard เก็บแค่ชื่อไฟล์ ยังไม่ส่งไฟล์ขึ้น API
2. **ฟอร์มสร้างรายการยืม/คืน** — ตอนนี้หน้า Borrow/Return ดู+อนุมัติ/ปฏิเสธได้ แต่ยังสร้างรายการใหม่จาก UI ไม่ได้ (API พร้อมแล้ว)
3. **Sign in with Google / สมัครสมาชิก / ลืมรหัสผ่าน** — ปุ่มและลิงก์มีตามดีไซน์ แต่ยังไม่มีปลายทาง
4. เมนูตามสิทธิ์ (role) · สลับภาษา EN/TH ให้ทำงานจริง
5. `npm run gen:api` แล้วใช้ type จาก `schema.d.ts` แทนการพิมพ์ type เอง
6. code splitting ต่อ route — bundle ตอนนี้ 1.85 MB (gzip 577 kB) เพราะ antd + recharts รวมก้อนเดียว
