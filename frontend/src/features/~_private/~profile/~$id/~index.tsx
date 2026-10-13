import {
  UserCircleIcon
} from '@heroicons/react/24/outline'
import { createFileRoute } from '@tanstack/react-router'
import React from 'react'

import StudyLayout from '@/components/study-layout'

export const Route = createFileRoute('/_private/profile/$id/')({
  component: RouteComponent,
})

// === COMPONENT CHÍNH CỦA TRANG ===
function RouteComponent() {
  return (
    <StudyLayout>

      <div className="min-h-screen bg-gray-50 p-4 md:p-8">
        <h1 className="mb-8 text-3xl font-bold text-gray-900">
          Hồ sơ cá nhân
        </h1>

        <div className="flex flex-col gap-8">
          <div className="flex flex-row items-stretch gap-8">

            {/* Section 1: Thông tin tài khoản */}
            <AccountInfoSection />

            {/* Section 2: Thông tin khác */}
            <OtherInfoSection />
          </div>

          {/* Section 3: Thông tin liên lạc */}
          <ContactInfoSection />
        </div>
      </div>
    </StudyLayout>
  )
}

// === CÁC SECTION CỦA TRANG ===

function AccountInfoSection() {
  return (
    <div className="flex flex-1 flex-col rounded-lg bg-white shadow-md">
      <div className="flex-1 p-6 md:p-8">
        <h2 className="mb-6 text-xl font-semibold text-gray-800">
          Thông tin tài khoản
        </h2>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
          {/* Avatar */}
          <div className="flex items-start justify-center md:col-span-1">
            <UserCircleIcon className="size-28 text-gray-400" />
          </div>

          {/* Fields */}
          <div className="space-y-4 md:col-span-3">
            <ReadOnlyField
              label="Tên tài khoản:"
              value="Nguyễn Trần Văn AAA"
            />
            <ReadOnlyField
              label="Tên hiển thị:"
              value="Nguyễn Trần Văn AAA"
            />
          </div>
        </div>
      </div>
    </div>
  )
}

function OtherInfoSection() {
  return (
    <div className="flex flex-1 flex-col rounded-lg bg-white shadow-md">
      <div className="flex-1 p-6 md:p-8">
        <h2 className="mb-6 text-xl font-semibold text-gray-800">
          Thông tin khác
        </h2>

        <div className="flex flex-col gap-4">
          <ReadOnlyField
            label="Ngày sinh:"
            value="01/01/2000"
          />
          <ReadOnlyField
            label="Lớp:"
            value="12A1"
          />
          <ReadOnlyField
            label="Tỉnh/Thành phố:"
            value="Thành phố Hồ Chí Minh"
          />
          <ReadOnlyField
            label="Trường THPT:"
            value="THPT Chuyên Lê Hồng Phong"
          />
        </div>
      </div>
    </div>
  )
}

function ContactInfoSection() {
  return (
    <div className="rounded-lg bg-white shadow-md">
      <div className="p-6 md:p-8">
        <h2 className="mb-6 text-xl font-semibold text-gray-800">
          Thông tin liên lạc
        </h2>

        <div className="space-y-4">
          <ReadOnlyField
            label="Email:"
            value="nguyentranvanaaa123456789@gmail.com"
            vertical={true}
          />
          <ReadOnlyField
            label="Số điện thoại:"
            value="0123456789"
          />
          <ReadOnlyField
            label="Tên tài khoản Facebook:"
            value="Nguyễn Trần Văn AAA"
          />
          <div className="grid grid-cols-3 items-center">
            <span className="text-sm font-medium text-gray-700">Đường dẫn Facebook:</span>
            <a
              href="https://facebook.com/nguyentranvanaaa"
              target="_blank"
              rel="noopener noreferrer"
              className="col-span-2 break-words text-sm font-medium text-blue-600 hover:underline"
            >
              https://facebook.com/nguyentranvanaaa
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}

// === COMPONENT HELPER ===



// Component cho các trường chỉ đọc (read-only)
interface ReadOnlyFieldProps {
  label: string
  value: string
  vertical?: boolean // true nếu muốn label_stack_trên_value
}

function ReadOnlyField({ label, value, vertical = false }: ReadOnlyFieldProps) {
  if (vertical) {
    return (
      <div>
        <span className="mb-1 block text-sm font-medium text-gray-700">{label}</span>
        <span className="text-sm font-medium text-gray-900">{value}</span>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-3 items-center">
      <span className="text-sm font-medium text-gray-700">{label}</span>
      <span className="col-span-2 text-sm font-medium text-gray-900">{value}</span>
    </div>
  )
}
