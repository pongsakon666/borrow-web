import {
  Area,
  Bar,
  BarChart,
  Cell,
  ComposedChart,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  type TooltipContentProps,
  type TooltipValueType,
} from 'recharts'
import { CHART_COLORS } from '@/app/theme'
import { formatNumber } from '@/shared/utils/format'

/** ตัวอักษรแกน — Inter 12 ดำโปร่ง 40% ตามดีไซน์ */
const AXIS = { fontSize: 12, fill: 'rgba(0, 0, 0, 0.4)' }
/** แกน Y กว้าง 23 + ช่องว่าง 16 */
const Y_WIDTH = 39

const tickFormatter = (value: number) => (value >= 1000 ? `${value / 1000}K` : String(value))

const SERIES_LABEL: Record<string, string> = {
  current: 'ปีนี้',
  previous: 'ปีที่แล้ว',
  value: 'จำนวนรายการ',
}

/** tooltip พื้นดำโปร่ง มุมโค้ง 8 ตัวอักษรขาว (ตามดีไซน์) */
function DarkTooltip({ active, payload }: TooltipContentProps<TooltipValueType, string | number>) {
  if (!active || !payload?.length) return null
  const multi = payload.length > 1
  return (
    <div className="chart-tooltip">
      {payload.map((item) => (
        <span key={String(item.dataKey)}>
          {multi && `${SERIES_LABEL[String(item.dataKey)] ?? item.name}: `}
          {formatNumber(Number(item.value ?? 0))}
        </span>
      ))}
    </div>
  )
}

/** กราฟเส้น "การใช้งาน" — ปีนี้ (เส้นดำ + พื้นไล่สี) เทียบปีที่แล้ว (เส้นประฟ้า) */
export function UsageChart({
  data,
}: {
  data: { month: string; current: number; previous: number }[]
}) {
  return (
    <ResponsiveContainer width="100%" height={246}>
      <ComposedChart data={data} margin={{ top: 8, right: 0, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="usageFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#000000" stopOpacity={0.08} />
            <stop offset="100%" stopColor="#000000" stopOpacity={0} />
          </linearGradient>
        </defs>
        <XAxis
          dataKey="month"
          tick={AXIS}
          axisLine={false}
          tickLine={false}
          tickMargin={12}
          padding={{ left: 16, right: 16 }}
        />
        <YAxis
          width={Y_WIDTH}
          tick={AXIS}
          tickMargin={10}
          axisLine={false}
          tickLine={false}
          tickCount={4}
          tickFormatter={tickFormatter}
        />
        <Tooltip content={DarkTooltip} cursor={{ stroke: 'rgba(0, 0, 0, 0.1)' }} />
        <Area
          type="monotone"
          dataKey="current"
          stroke="#000000"
          strokeWidth={1.5}
          fill="url(#usageFill)"
          activeDot={{ r: 4, fill: '#000000', strokeWidth: 0 }}
        />
        <Line
          type="monotone"
          dataKey="previous"
          stroke="#a0bce8"
          strokeWidth={1}
          strokeDasharray="4 4"
          dot={false}
          activeDot={{ r: 3, fill: '#a0bce8', strokeWidth: 0 }}
        />
      </ComposedChart>
    </ResponsiveContainer>
  )
}

/** กราฟแท่ง "สถิติประจำปี" — แท่งมน 28px สีไล่ตาม CHART_COLORS */
export function YearlyChart({ data }: { data: { month: string; value: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={196}>
      <BarChart data={data} margin={{ top: 8, right: 0, left: 0, bottom: 0 }}>
        <XAxis dataKey="month" tick={AXIS} axisLine={false} tickLine={false} tickMargin={12} />
        <YAxis
          width={Y_WIDTH}
          tick={AXIS}
          tickMargin={10}
          axisLine={false}
          tickLine={false}
          tickCount={4}
          tickFormatter={tickFormatter}
        />
        <Tooltip content={DarkTooltip} cursor={false} />
        <Bar dataKey="value" barSize={28} radius={8} minPointSize={4}>
          {data.map((entry, index) => (
            <Cell key={entry.month} fill={CHART_COLORS[index % CHART_COLORS.length]} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}

/** โทนของแถบ 3 ท่อน: ดำ / ดำ 40% / ดำ 10% */
const SEGMENT_OPACITY = [1, 0.4, 0.1]

/** รายการ "ครุภัณฑ์ยอดนิยม" — แถบ 3 ท่อน ความยาวตามสัดส่วนเทียบตัวที่ถูกยืมมากที่สุด */
export function PopularList({ data }: { data: { name: string; value: number }[] }) {
  const max = Math.max(1, ...data.map((d) => d.value))

  return (
    <ul className="popular-list" data-testid="popular-list">
      {data.map((item) => {
        // ความยาวขั้นต่ำ 30% ให้ยังเห็นครบ 3 ท่อน
        const width = 30 + (item.value / max) * 70
        return (
          <li key={item.name} title={`${item.name}: ${formatNumber(item.value)}`}>
            <span className="popular-list__name">{item.name}</span>
            <span className="popular-list__bar" style={{ width: `${width}%` }}>
              {SEGMENT_OPACITY.map((opacity) => (
                <i key={opacity} style={{ opacity }} />
              ))}
            </span>
            <span className="sr-only">{formatNumber(item.value)}</span>
          </li>
        )
      })}
    </ul>
  )
}
