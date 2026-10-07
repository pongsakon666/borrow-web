import type { ThemeConfig } from 'antd'

/**
 * Design token กลางของระบบ (ตาม Figma "Design - Admin") — แก้ที่นี่ที่เดียว
 * ต้องตรงกับตัวแปร :root ใน styles.css
 */
export const BRAND = {
  /** ปุ่มหลัก / เมนูที่เลือก — ม่วงคราม */
  primary: '#4f46e5',
  primarySoft: '#eef2ff',
  /** ปุ่มเน้นฝั่ง Return / Calendar */
  pink: '#e91868',
  /** โลโก้ RP.Rent */
  blue: '#1470ff',
  /** ปุ่ม "เพิ่มรายการ" หน้า Borrow */
  sky: '#0284c7',
  /** ปุ่มใน modal ยืนยัน */
  violet: '#7f56d9',
  danger: '#d92d20',
  success: '#50cd89',
  warning: '#f97316',
  ink: '#101010',
  navy: '#081021',
  slate: '#64748b',
  muted: '#878787',
  border: '#ededed',
  line: '#e2e8f0',
  surface: '#ffffff',
  canvas: '#f5f6fa',
} as const

/** สีของ pill สถานะ — ใช้คู่กับ <StatusPill tone=...> */
export const TONE = {
  pink: { bg: 'rgba(233, 24, 104, 0.1)', fg: '#e91868' },
  green: { bg: 'rgba(80, 205, 137, 0.1)', fg: '#50cd89' },
  gray: { bg: 'rgba(135, 135, 135, 0.1)', fg: '#878787' },
  purple: { bg: 'rgba(114, 57, 234, 0.12)', fg: '#7239ea' },
  blue: { bg: '#e6f1fd', fg: '#1470ff' },
  orange: { bg: '#fff4e5', fg: '#f97316' },
  red: { bg: '#fee4e2', fg: '#d92d20' },
} as const

export type Tone = keyof typeof TONE

/** สถานะ transaction → pill (ตารางรายการล่าสุดบน Dashboard) */
export const STATUS_COLOR = {
  in_progress: { bg: '#eef0fe', fg: '#8a8cf5' },
  complete: { bg: '#e6f8ef', fg: '#4ade80' },
  pending: { bg: '#e8f2fd', fg: '#7cb6f5' },
  approved: { bg: '#fff5e6', fg: '#fdba74' },
  rejected: { bg: '#f1f1f1', fg: '#9ca3af' },
} as const

/** จานสีกราฟแท่งรายปี — ไล่ตามดีไซน์ */
export const CHART_COLORS = [
  '#a0a4f5',
  '#96e2d6',
  '#000000',
  '#94c0fc',
  '#b0c9ee',
  '#94e8b8',
  '#a0a4f5',
  '#96e2d6',
  '#000000',
  '#94c0fc',
  '#b0c9ee',
  '#94e8b8',
]

/** Inter/Poppins ไม่มีอักษรไทย — ให้ IBM Plex Sans Thai รับช่วง */
export const FONT_STACK =
  "'Inter', 'IBM Plex Sans Thai', 'Noto Sans Thai', system-ui, -apple-system, 'Segoe UI', sans-serif"

export const HEADING_FONT =
  "'Poppins', 'IBM Plex Sans Thai', 'Noto Sans Thai', system-ui, -apple-system, 'Segoe UI', sans-serif"

export const antdTheme: ThemeConfig = {
  token: {
    colorPrimary: BRAND.primary,
    colorLink: BRAND.primary,
    colorTextBase: BRAND.ink,
    colorTextSecondary: BRAND.muted,
    colorBorder: '#e2e8f0',
    colorBorderSecondary: BRAND.border,
    colorBgLayout: BRAND.canvas,
    colorError: BRAND.danger,
    colorSuccess: BRAND.success,
    fontFamily: FONT_STACK,
    fontSize: 14,
    borderRadius: 8,
    controlHeight: 40,
    wireframe: false,
  },
  components: {
    Button: { controlHeight: 44, fontWeight: 600, primaryShadow: 'none', defaultShadow: 'none' },
    Input: { controlHeight: 44, paddingInline: 16 },
    InputNumber: { controlHeight: 44 },
    Select: { controlHeight: 44 },
    DatePicker: { controlHeight: 44 },
    Layout: {
      headerBg: BRAND.surface,
      headerHeight: 71,
      headerPadding: '0 64px',
      siderBg: BRAND.surface,
      bodyBg: BRAND.canvas,
    },
    Menu: {
      itemBg: 'transparent',
      itemColor: BRAND.slate,
      itemHoverColor: BRAND.primary,
      itemHoverBg: '#f5f7ff',
      itemSelectedBg: BRAND.primarySoft,
      itemSelectedColor: BRAND.primary,
      itemHeight: 44,
      itemMarginInline: 24,
      itemMarginBlock: 4,
      itemBorderRadius: 99,
      iconSize: 20,
      collapsedIconSize: 20,
    },
    Card: { paddingLG: 24, headerHeight: 56 },
    Table: {
      headerBg: '#f9f9fa',
      headerColor: BRAND.muted,
      headerSplitColor: 'transparent',
      rowHoverBg: '#fafbfd',
      borderColor: BRAND.border,
    },
    Modal: { borderRadiusLG: 16 },
    Switch: { colorPrimary: '#2563eb' },
  },
}
