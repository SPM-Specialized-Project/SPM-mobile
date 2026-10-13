"use client" // Cần thiết cho Recharts vì nó dùng client-side hooks

import React from 'react'
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'

// 1. Dữ liệu mockup cho biểu đồ tròn "Cơ cấu điểm số"
const scoreDistributionData = [
  { name: '0 - 4,5 Điểm', value: 6 },
  { name: '4,5 - 7,5 Điểm', value: 12 },
  { name: '7,5 - 10 Điểm', value: 6 },
]

// Màu mặc định cho các slices
const DEFAULT_COLORS = ['#EF4444', '#FCD34D', '#10B981']

interface ScorePieChartProps {
  title: string
  // optional data to render; if not provided we use internal mock
  data?: Array<{ name: string; value: number }>
  // optional color palette
  colors?: string[]
  // outer radius of the pie (defaults to 120)
  outerRadius?: number
}

/**
 * Component hiển thị biểu đồ tròn cho "Cơ cấu điểm số"
 */
export function ScorePieChart({
  title,
  data,
  colors = DEFAULT_COLORS,
  outerRadius = 120,
}: ScorePieChartProps) {
  const chartData = data ?? scoreDistributionData

  const renderCustomizedLabel = ({
    cx,
    cy,
    midAngle,
    innerRadius,
    outerRadius: rOuter,
    value,
  }: any) => {
    const radius = innerRadius + (rOuter - innerRadius) * 0.5
    const x = cx + radius * Math.cos(-midAngle * Math.PI / 180)
    const y = cy + radius * Math.sin(-midAngle * Math.PI / 180)

    return (
      <text
        x={x}
        y={y}
        fill="white"
        textAnchor={x > cx ? 'start' : 'end'}
        dominantBaseline="central"
        className="text-lg font-semibold"
      >
        {value}
      </text>
    )
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-lg">
      <h3 className="mb-4 text-center text-lg font-semibold text-gray-800">{title}</h3>

      {/* Use Tailwind height utility instead of inline style */}
      <div className="h-[350px]">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={chartData}
              cx="50%"
              cy="50%"
              labelLine={false}
              label={renderCustomizedLabel}
              outerRadius={outerRadius}
              fill="#8884d8"
              dataKey="value"
            >
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
              ))}
            </Pie>

            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                borderRadius: '8px',
                borderColor: '#ccc',
              }}
            />

            <Legend wrapperStyle={{ paddingTop: '20px' }} verticalAlign="bottom" align="center" />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

export default ScorePieChart
