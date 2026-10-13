import { createFileRoute, Link } from '@tanstack/react-router'
import { useState } from 'react'

import { ArrowLeft } from '@/components/icons'
import StudyLayout from '@/components/study-layout'
import ScoreBarChart from '@/features/~_private/~statistical/~reports/components/chart-placeholder'
import { FilterPopup } from '@/features/~_private/~statistical/~reports/components/filter-popup'
import ScorePieChart from '@/features/~_private/~statistical/~reports/components/score-piechart'
export const Route = createFileRoute('/_private/statistical/reports/')({
  component: RouteComponent,
})

// --- Dữ liệu mockup dựa trên hình ảnh ---
const statsData = [
  { label: 'Điểm trung bình', value: '5.75' },
  { label: 'Bài nộp', value: '125' },
  { label: 'Sinh viên', value: '10' },
  { label: 'Giảng viên', value: '2' },
  { label: 'Đánh giá trung bình', value: '4' },
  { label: 'Đánh giá', value: '12' },
  { label: 'Buổi vắng', value: '15' },
  { label: 'Báo cáo', value: '1' },
]
// Dữ liệu mockup cho biểu đồ tròn
const scoreDistributionData = [
  { name: '0 - 4,5 Điểm', value: 6 },
  { name: '4,5 - 7,5 Điểm', value: 12 },
  { name: '7,5 - 10 Điểm', value: 6 },
]


// --- Component con để tái sử dụng ---

/**
 * Hiển thị một thẻ thống kê (8 thẻ màu vàng ở trên cùng)
 */
function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="flex h-[140px] flex-col items-center justify-center rounded-lg  bg-white p-4 text-center shadow-custom-yellow">
      <span className="text-5xl font-bold text-blue-700">{value}</span>
      <span className="mt-2 text-base font-semibold text-gray-700">
        {label}
      </span>
    </div>
  )
}

// Optional: mock score data used for the score distribution chart.
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

// --- Component chính của trang ---

function RouteComponent() {
  const [showFilter, setShowFilter] = useState(false);

  return (
    <StudyLayout>

      <div className="min-h-full bg-gray-100 p-6">
        <div className="mb-8 flex items-center justify-between">
          <Link
            to="/statistical"
            className="mb-6 flex items-center gap-2 text-[#3D4863] transition hover:text-blue-700"
          >
            <ArrowLeft className="size-5" />
            <span className="font-medium">Quay lại</span>
          </Link>

          <div className="flex items-center gap-2">


            <button aria-label='filter' onClick={() => { setShowFilter(!showFilter) }} className="mr-3 shrink-0 rounded-xl border border-gray-600 p-3">
              <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M6.08309 12.0833C6.08304 12.2072 6.1175 12.3287 6.18262 12.4341C6.24774 12.5395 6.34094 12.6246 6.45176 12.68L7.78509 13.3467C7.88676 13.3975 7.99972 13.4214 8.11326 13.4163C8.22679 13.4112 8.33712 13.3771 8.43378 13.3173C8.53044 13.2575 8.6102 13.174 8.66551 13.0747C8.72081 12.9754 8.74981 12.8637 8.74976 12.75V8.08333C8.74991 7.75292 8.87274 7.43433 9.09443 7.18933L13.9098 1.86333C13.9961 1.76771 14.0528 1.64912 14.0732 1.52192C14.0935 1.39472 14.0765 1.26435 14.0244 1.14658C13.9722 1.02881 13.887 0.928682 13.7791 0.858301C13.6712 0.787921 13.5452 0.750304 13.4164 0.75H1.41643C1.2875 0.750047 1.16135 0.787477 1.05326 0.857758C0.94517 0.928038 0.859779 1.02815 0.807429 1.14598C0.75508 1.2638 0.738017 1.39427 0.758309 1.52159C0.778602 1.64892 0.835377 1.76762 0.92176 1.86333L5.73843 7.18933C5.96012 7.43433 6.08294 7.75292 6.08309 8.08333V12.0833Z" stroke="#3D4863" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
            <button className="flex items-center gap-2 rounded-md bg-[#0329E9] px-10 py-2 text-white shadow-sm hover:bg-blue-700">
              <span>Tải kết quả</span>
            </button>
          </div>
        </div>
        {showFilter && (
          <FilterPopup onClose={() => setShowFilter(false)} />
        )}
        {/* Phần 1: Các thẻ thống kê */}
        <div className="mb-8 grid grid-cols-2 gap-6 md:grid-cols-4">
          {statsData.map((stat) => (
            <StatCard key={stat.label} label={stat.label} value={stat.value} />
          ))}
        </div>

        {/* Phần 2: Hàng biểu đồ thứ nhất */}
        <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
          <ScoreBarChart title="Phổ điểm bài nộp" data={scoreData} />
          <ScorePieChart title="Cơ cấu điểm số" data={scoreDistributionData} />
        </div>

        {/* Phần 3: Hàng biểu đồ thứ hai */}
        <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
          <ScoreBarChart title="Tổng quan đánh giá" />
          <ScorePieChart title="Cơ cấu đánh giá" data={scoreDistributionData} />
        </div>

        {/* Phần 4: Hàng biểu đồ cuối cùng */}
        <div className="mb-8  ">
          <ScoreBarChart title="Thời gian hoạt động" />
        </div>
      </div>
    </StudyLayout>
  )
}
