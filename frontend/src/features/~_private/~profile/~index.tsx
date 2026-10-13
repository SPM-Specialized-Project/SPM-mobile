import {
  UserCircleIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline'
import { createFileRoute } from '@tanstack/react-router'
import React from 'react'

import StudyLayout from '@/components/study-layout'

export const Route = createFileRoute('/_private/profile/')({
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
            <InputField
              label="Tên hiển thị:"
              id="displayName"
              placeholder="Tên hiển thị là tên mà giáo viên sẽ thấy..."
              defaultValue="Nguyễn Trần Văn AAA" // Giả sử load từ API
            />

            <div className="flex items-center justify-between pt-2">
              <label className="text-sm font-medium text-gray-700">
                Thay đổi mật khẩu:
              </label>
              <div className="col-span-2">
                <button className="rounded-md bg-[#0329E9] px-5 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                  Thay đổi
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Nút bấm ở Footer */}
      <div className="flex justify-end gap-4 rounded-b-lg border-t border-gray-200 bg-gray-50 px-6 py-4">
        <button className="rounded-md bg-red-600 px-6 py-2 font-medium text-white transition-colors hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2">
          Đăng xuất
        </button>
        <button className="rounded-md bg-[#0329E9] px-6 py-2 font-medium text-white transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
          Cập nhật
        </button>
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
          <div className="relative w-full">
            <InputField
              label="Ngày sinh:"
              id="dob"
              placeholder="DD/MM/YYYY"
              type="text"
            />
            <CalendarDaysIcon className="pointer-events-none absolute right-3 top-[calc(1.75rem+8px)] size-5 text-gray-400" />
          </div>

          <div className="w-full">
            <InputField
              label="Lớp:"
              id="class"
              placeholder="Nhập lớp của bạn ở trường THPT"
            />
          </div>

          <div className="w-full">
            <InputField
              label="Tỉnh/Thành phố:"
              id="city"
              placeholder="Nhập tỉnh/thành phố nơi bạn cư trú"
            />
          </div>

          <div className="w-full">
            <InputField
              label="Trường THPT:"
              id="highSchool"
              placeholder="Nhập tên trường THPT bạn đang theo học"
            />
          </div>
        </div>
      </div>

      {/* Nút bấm ở Footer */}
      <div className="flex justify-end rounded-b-lg border-t border-gray-200 bg-gray-50 px-6 py-4">
        <button className="rounded-md bg-[#0329E9] px-6 py-2 font-medium text-white transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
          Cập nhật
        </button>
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

        <div className="">
          <ReadOnlyField
            label="Email:"
            value="nguyentranvanaaa123456789@gmail.com"
            vertical={true}
          />
          <InputField
            label="Số điện thoại:"
            id="phone"
            placeholder="Nhập số điện thoại liên lạc của bạn"
          />
          <InputField
            label="Tên tài khoản Facebook:"
            id="fbName"
            placeholder="Nháp tên tài khoản Facebook bạn dùng để tham gia Nhóm Facebook"
          />
          <InputField
            label="Đường dẫn Facebook:"
            id="fbUrl"
            placeholder="Nhập đường dẫn đến trang cá nhân Facebook của bạn"
          />
        </div>
      </div>

      {/* Nút bấm ở Footer */}
      <div className="flex justify-end rounded-b-lg border-t border-gray-200 bg-gray-50 px-6 py-4">
        <button className="rounded-md bg-[#0329E9] px-6 py-2 font-medium text-white transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
          Cập nhật
        </button>
      </div>
    </div>
  )
}

// === COMPONENT HELPER ===

// Component cho các trường input
interface InputFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string
  id: string
}

function InputField({ label, id, ...props }: InputFieldProps) {
  return (
    <div>
      <label htmlFor={id} className="mb-1 block text-sm font-medium text-gray-700">
        {label}
      </label>
      <input
        id={id}
        {...props}
        className="w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500"
      />
    </div>
  )
}

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
