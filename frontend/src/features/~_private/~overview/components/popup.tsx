import { XMarkIcon, CheckCircleIcon } from '@heroicons/react/24/solid';
import React, { useState, type SVGProps } from 'react';

import { PastRegistration } from '@/components/data/~mock-register';

/**
 * Props cho component MatchingPopup
 */
interface MatchingPopupProps {
  onClose: () => void;
  // Hàm onMatch sẽ trả về ID của person được chọn
  onMatch: (selectedPersonId: string) => void;
  // Danh sách người có thể match
  // availablePeople: Array<{ id: string; name: string,  }>;
  availablePeople: PastRegistration[];
  // Label cho tab (Tutor hoặc Student)
  tabLabel: string;
}

// --- Component Avatar ---
const TutorAvatar = (props: SVGProps<SVGSVGElement>) => (
  <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-gray-800">
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      className="size-5 text-gray-300"
      {...props}
    >
      <path
        fillRule="evenodd"
        d="M12 12a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H5z"
        clipRule="evenodd"
      />
    </svg>
  </div>
);

/**
 * Component Popup để "Match"
 */
export function MatchingPopup({ onClose, onMatch, availablePeople, tabLabel }: MatchingPopupProps) {

  // State để lưu ID của person được chọn
  const [selectedPersonId, setSelectedPersonId] = useState<string | null>(
    availablePeople[0]?.id ?? null
  );

  // Ngăn việc click vào nội dung card làm đóng popup
  const handleCardClick = (e: React.MouseEvent) => {
    e.stopPropagation();
  };

  // Xử lý khi bấm nút "Match"
  const handleMatchClick = () => {
    if (selectedPersonId) {
      onMatch(selectedPersonId);
      onClose();
    }
  };

  return (
    // Lớp phủ (Overlay) - Backdrop mờ và tối
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm transition-opacity"
      onClick={onClose}
    >
      {/* Container của Popup: Rộng hơn (max-w-3xl) nhưng bo góc mềm mại */}
      <div
        className="w-full max-w-3xl overflow-hidden rounded-2xl bg-white shadow-2xl transition-all"
        onClick={handleCardClick}
      >

        {/* --- Header --- */}
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4">
          <div>
            {/* Header nhỏ lại (text-xl thay vì 4xl) */}
            <h2 className="text-xl font-bold text-gray-900">Matching</h2>
            <p className="mt-1 text-xs text-gray-500">Chọn người phù hợp nhất từ danh sách bên dưới</p>
          </div>
          <button
            onClick={onClose}
            className="rounded-full bg-gray-100 p-1.5 text-gray-500 transition hover:bg-gray-200 hover:text-gray-700 focus:outline-none"
            aria-label="Đóng popup"
          >
            <XMarkIcon className="size-5" />
          </button>
        </div>

        {/* --- Body (Nội dung chính) --- */}
        <div className="flex flex-col px-6 py-5">
          {/* Tab Label & Counter */}
          <div className="mb-3 flex items-center justify-between">
            <span className="rounded-full bg-blue-50 px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide text-blue-600">
              {tabLabel}
            </span>
            <span className="text-xs text-gray-400">
              {availablePeople.length} kết quả
            </span>
          </div>

          {/* Danh sách: Cao hơn (h-96) để hiển thị nhiều item */}
          {/* Custom Scrollbar css (nếu hỗ trợ) hoặc mặc định */}
          <div className="h-96 overflow-y-auto pr-2">
            <div className="space-y-2">
              {availablePeople.length === 0 ? (
                <div className="flex h-full flex-col items-center justify-center py-10 text-sm text-gray-500">
                  Không tìm thấy kết quả phù hợp
                </div>
              ) : (
                availablePeople.map((person) => {
                  const isSelected = selectedPersonId === person.id;
                  return (
                    <label
                      key={person.id}
                      tabIndex={0}
                      onKeyDown={(e) => {
                        if (e.key === ' ' || e.key === 'Enter') {
                          e.preventDefault();
                          setSelectedPersonId((s) => (s === person.id ? null : person.id));
                        }
                      }}
                      className={`
                        group relative flex cursor-pointer items-center gap-3 rounded-lg border px-3 py-2.5 transition-all duration-200 ease-in-out
                        ${isSelected
                          ? 'border-blue-500 bg-blue-50/60 shadow-sm ring-blue-500'
                          : 'border-gray-200 bg-white hover:border-blue-300 hover:bg-gray-50'
                        }
                      `}
                    >
                      {/* Checkbox ẩn (Logic) */}
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => setSelectedPersonId((s) => (s === person.id ? null : person.id))}
                        className="sr-only"
                      />

                      <div className="relative">
                        <TutorAvatar />
                        {isSelected && (
                          <div className="absolute -bottom-1 -right-1 rounded-full bg-white ring-2 ring-white">
                            <CheckCircleIcon className="size-4 text-blue-600" />
                          </div>
                        )}
                      </div>

                      <div className="flex-1">
                        <span className={`block text-sm font-semibold ${isSelected ? 'text-blue-900' : 'text-gray-900'}`}>
                          {person.Name}
                        </span>
                        <span className="text-[10px] text-gray-400 group-hover:text-gray-500">
                          ID: {person.id}
                        </span>
                        <span className="block text-xs text-gray-500 group-hover:text-gray-700">
                          Email: {person.Email}
                        </span>
                        <span className="block text-xs text-gray-500 group-hover:text-gray-700">
                          Môn học: {person.subjects.map(s => s.name).join(', ')}
                        </span>
                        <span className="block text-xs text-gray-500 group-hover:text-gray-700">
                          Loại hình: {person.sessionTypes.map(s => s.name).join(', ')}
                        </span>
                      </div>

                      {/* Visual Radio Indicator */}
                      <div className={`flex size-4 items-center justify-center rounded-full border ${isSelected ? 'border-blue-500 bg-blue-500' : 'border-gray-300'}`}>
                        {isSelected && <div className="size-1.5 rounded-full bg-white" />}
                      </div>
                    </label>
                  );
                })
              )}
            </div>
          </div>
        </div>

        {/* --- Footer (Nút Match) --- */}
        <div className="border-t border-gray-100 bg-gray-50 px-6 py-4">
          <button
            onClick={handleMatchClick}
            disabled={!selectedPersonId}
            className={`
              w-full rounded-lg py-3 text-sm font-bold text-white shadow-md transition-all
              focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
              ${selectedPersonId
                ? 'bg-blue-600 hover:-translate-y-0.5 hover:bg-blue-700 hover:shadow-blue-500/30'
                : 'cursor-not-allowed bg-gray-300 opacity-70'
              }
            `}
          >
            Ghép đôi
          </button>
        </div>

      </div>
    </div>
  );
}
