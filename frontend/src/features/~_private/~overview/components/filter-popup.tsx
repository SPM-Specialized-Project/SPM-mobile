import { XMarkIcon } from '@heroicons/react/24/solid';
import React, { useState, useMemo } from 'react';
// Import icons

// Import mock data (điều chỉnh đường dẫn nếu cần)
import {
  mockLocations,
  mockLanguages
} from '@/components/data/~mock-register';

// --- Dữ liệu tĩnh cho các mục không có trong mock (dựa trên ảnh) ---

// Dữ liệu cho Role
const roleOptions = [
  { id: 'student', name: 'Student' },
  { id: 'tutor', name: 'Tutor' },
];

// Dữ liệu cho Hình thức
const sessionTypeOptions = [
  { id: 'online', name: 'online' },
  { id: 'hybrid', name: 'hybrid' },
];

// // --- Định nghĩa Types ---
// interface DropdownOption {
//   id: string;
//   name: string;
// }

// Kiểu dữ liệu cho state của filters
export interface FilterState {
  locations: Record<string, boolean>; // { p1: true, p2: true, ... }
  language: string; // 'en'
  role: string; // 'student'
  sessionType: string; // 'hybrid'
}

/**
 * Props cho component FilterPopup
 */
interface FilterPopupProps {
  onClose: () => void;
  // Gửi state của filter về cho component cha
  onApply: (filters: FilterState) => void;
  // Nhận state khởi tạo (nếu có)
  initialState?: Partial<FilterState>;
}

/**
 * Component Popup để lọc
 */
export function FilterPopup({ onClose, onApply, initialState }: FilterPopupProps) {

  // --- State ---
  // Tạo state ban đầu
  const [filters, setFilters] = useState<FilterState>(() => {
    // 1. Mặc định cho locations
    const defaultLocations: Record<string, boolean> = {};

    // Dựa theo ảnh, lấy 6 location đầu tiên và check 4 cái
    // (Bỏ qua việc lặp lại "Phường 1" trong ảnh, dùng data mock)
    mockLocations.slice(0, 6).forEach((loc, index) => {
      // Ảnh check 4, uncheck 2
      defaultLocations[loc.id] = index < 4;
    });

    // 2. Gộp state mặc định với state được truyền vào (nếu có)
    return {
      locations: initialState?.locations ?? defaultLocations,
      language: initialState?.language ?? 'en', // 'Tiếng Anh' (từ ảnh)
      role: initialState?.role ?? 'student', // 'Student' (từ ảnh)
      sessionType: initialState?.sessionType ?? 'hybrid', // 'Hybrid' (từ ảnh)
    };
  });

  // --- Handlers ---

  // Xử lý thay đổi checkbox (Địa điểm)
  const handleLocationChange = (id: string) => {
    setFilters(prev => ({
      ...prev,
      locations: {
        ...prev.locations,
        [id]: !prev.locations[id], // Toggle
      }
    }));
  };

  // Xử lý thay đổi radio (Ngôn ngữ, Role, Hình thức)
  const handleRadioChange = (
    field: 'language' | 'role' | 'sessionType',
    id: string
  ) => {
    setFilters(prev => ({
      ...prev,
      [field]: id,
    }));
  };

  // Tính toán số lượng filter được áp dụng
  const filterCount = useMemo(() => {
    const locationCount = Object.values(filters.locations).filter(Boolean).length;
    // Mỗi group radio luôn có 1 giá trị, nên + 3
    return locationCount + 3;
    // Hoặc bạn có thể dùng số 11 cứng từ ảnh
    // return 11;
  }, [filters]);

  // Ngăn việc click vào nội dung card làm đóng popup
  const handleCardClick = (e: React.MouseEvent) => {
    e.stopPropagation();
  };

  // Xử lý bấm Apply
  const handleApplyClick = () => {
    onApply(filters);
    onClose();
  };

  return (
    // Lớp phủ (Overlay)
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      onClick={onClose}
    >
      {/* Container của Popup (Card) */}
      <div
        className="relative flex w-full max-w-sm flex-col rounded-2xl bg-white shadow-xl"
        onClick={handleCardClick}
      >

        {/* Header: "Filter" và nút X */}
        <div className="flex items-center justify-between p-6">
          <h2 className="text-3xl font-bold text-gray-900">Filter</h2>
          <button
            onClick={onClose}
            className="rounded-full bg-gray-200 p-1.5 text-gray-600 transition hover:bg-gray-300"
            aria-label="Đóng popup"
          >
            <XMarkIcon className="size-5" />
          </button>
        </div>

        {/* Body (scrollable) */}
        <div className="max-h-[70vh] flex-1 overflow-y-auto p-6 pt-0">
          <div className="space-y-6">

            {/* Địa điểm Section */}
            <div>
              <h3 className="mb-3 text-lg font-semibold text-gray-900">Địa điểm</h3>
              <div className="h-48 space-y-3 overflow-y-auto rounded-lg border border-gray-300 p-4">
                {/* Chỉ hiển thị 6 cái như trong ảnh */}
                {mockLocations.slice(0, 6).map(loc => (
                  <label key={loc.id} className="flex cursor-pointer items-center">
                    <input
                      type="checkbox"
                      checked={filters.locations[loc.id] || false}
                      onChange={() => handleLocationChange(loc.id)}
                      className="size-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    <span className="ml-3 text-sm text-gray-700">{loc.name}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Ngôn ngữ Section */}
            <div>
              <h3 className="mb-3 text-lg font-semibold text-gray-900">Ngôn ngữ</h3>
              <div className="space-y-3 rounded-lg border border-gray-300 p-4">
                {/* Chỉ hiển thị Tiếng Anh, Tiếng Việt như trong ảnh */}
                {mockLanguages.filter(l => l.id === 'en' || l.id === 'vi').map(lang => (
                  <label key={lang.id} className="flex cursor-pointer items-center">
                    <input
                      type="radio"
                      name="language"
                      value={lang.id}
                      checked={filters.language === lang.id}
                      onChange={() => handleRadioChange('language', lang.id)}
                      className="size-5 text-blue-600 focus:ring-blue-500"
                    />
                    <span className="ml-3 text-sm text-gray-700">{lang.name}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Role Section */}
            <div>
              <h3 className="mb-3 text-lg font-semibold text-gray-900">Role</h3>
              <div className="space-y-3 rounded-lg border border-gray-300 p-4">
                {roleOptions.map(role => (
                  <label key={role.id} className="flex cursor-pointer items-center">
                    <input
                      type="radio"
                      name="role"
                      value={role.id}
                      checked={filters.role === role.id}
                      onChange={() => handleRadioChange('role', role.id)}
                      className="size-5 text-blue-600 focus:ring-blue-500"
                    />
                    <span className="ml-3 text-sm text-gray-700">{role.name}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Hình thức Section */}
            <div>
              <h3 className="mb-3 text-lg font-semibold text-gray-900">Hình thức</h3>
              <div className="space-y-3 rounded-lg border border-gray-300 p-4">
                {sessionTypeOptions.map(type => (
                  <label key={type.id} className="flex cursor-pointer items-center">
                    <input
                      type="radio"
                      name="sessionType"
                      value={type.id}
                      checked={filters.sessionType === type.id}
                      onChange={() => handleRadioChange('sessionType', type.id)}
                      className="size-5 text-blue-600 focus:ring-blue-500"
                    />
                    <span className="ml-3 text-sm text-gray-700">{type.name}</span>
                  </label>
                ))}
              </div>
            </div>

          </div>
        </div> {/* End Body */}

        {/* Footer */}
        <div className="rounded-b-2xl bg-gray-50 p-6">
          <button
            onClick={handleApplyClick}
            className="flex w-full items-center justify-between rounded-lg bg-blue-800 px-5 py-3 text-white shadow-md transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            <span className="text-base font-semibold">Apply Filter</span>
            <span className="flex size-7 items-center justify-center rounded-full bg-white text-sm font-bold text-blue-800">
              {filterCount}
            </span>
          </button>
        </div>

      </div> {/* End Card */}
    </div>
  );
}
