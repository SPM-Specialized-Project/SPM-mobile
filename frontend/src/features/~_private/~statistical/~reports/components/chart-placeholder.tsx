"use client"

import React from 'react'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'

// Dữ liệu mockup biểu đồ đường
const scoreData = [
  { score: '0', 'Bài nộp': 20 },
  { score: '1', 'Bài nộp': 25 },
  { score: '2', 'Bài nộp': 20 },
  { score: '3', 'Bài nộp': 100 },
  { score: '4', 'Bài nộp': 90 },
  { score: '5', 'Bài nộp': 80 },
  { score: '6', 'Bài nộp': 100 },
  { score: '7', 'Bài nộp': 100 },
  { score: '8', 'Bài nộp': 100 },
  { score: '9', 'Bài nộp': 100 },
  { score: '10', 'Bài nộp': 100 },
]


interface ChartPlaceholderProps {
  title: string
  // optional data prop; if not provided the component falls back to internal mock
  data?: Array<Record<string, any>>
}

/**
 * Component hiển thị biểu đồ cột cho Phổ điểm
 */
export function ScoreBarChart({ title, data }: ChartPlaceholderProps) {
  const chartData = data ?? scoreData

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-lg">
      <h3 className="mb-4 text-center text-lg font-semibold text-gray-800">
        {title}
      </h3>
      {/* Vùng chứa biểu đồ cần có chiều cao cố định */}
      <div className="h-[350px]">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={chartData}
            barCategoryGap="20%"
            barGap={4}
            margin={{
              top: 5,
              right: 20,
              left: 10,
              bottom: 20,
            }}
          >
            {/* Lưới tọa độ mờ */}
            <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />

            {/* Trục X - là các điểm số */}
            <XAxis
              dataKey="score"
              label={{
                value: 'Điểm số',
                position: 'insideBottom',
                offset: -10,
              }}
              tick={{ fontSize: 12 }}
            />

            {/* Trục Y - là số lượng bài nộp */}
            <YAxis
              label={{
                value: 'Số lượng bài nộp',
                angle: -90,
                position: 'insideLeft',
                dx: -10,
              }}
              tick={{ fontSize: 12 }}
            />

            {/* Tooltip khi hover chuột vào cột */}
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                borderRadius: '8px',
                borderColor: '#ccc',
              }}
            />

            {/* Cột dữ liệu */}
            <Bar dataKey="Bài nộp" fill="#0000FF" maxBarSize={50} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

// Export default để tiện dùng
export default ScoreBarChart
