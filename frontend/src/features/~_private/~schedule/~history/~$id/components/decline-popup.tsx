import { XMarkIcon } from '@heroicons/react/24/solid';
import React, { useState } from 'react';

import useLockBodyScroll from '@/hooks/use-lock-body-scroll';
// Bạn cần cài đặt heroicons: npm install @heroicons/react

/**
 * Props cho component DeclinePopup
 */
interface DeclinePopupProps {
  onClose: () => void;
  onSubmit: (reason: string) => void;
}

/**
 * Component Popup để nhập lý do từ chối
 */
export function DeclinePopup({ onClose, onSubmit }: DeclinePopupProps) {
  // State để lưu nội dung lý do
  const [reason, setReason] = useState('');

  // Lock background scroll while this popup is mounted
  useLockBodyScroll(true);

  // Ngăn việc click vào nội dung card làm đóng popup
  const handleCardClick = (e: React.MouseEvent) => {
    e.stopPropagation();
  };

  // Xử lý khi bấm nút "Gửi"
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault(); // Ngăn form submit
    onSubmit(reason);
  };

  return (
    // Lớp phủ (Overlay)
    <div
  className="fixed inset-0 z-[50000] flex items-center justify-center bg-gray-900/75 p-4"
      onClick={onClose} // Click vào overlay để đóng
    >
      {/* Container của Popup (Card) */}
      <div
        className="relative w-full max-w-lg rounded-lg bg-white p-6 shadow-xl"
        onClick={handleCardClick}
      >
        {/* Header: Tiêu đề và nút X */}
        <div className="mb-4 flex items-start justify-between">
          <h2 className="text-xl font-bold text-red-600">
            Lý do từ chối
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
            aria-label="Đóng"
          >
            <XMarkIcon className="size-6" />
          </button>
        </div>

        {/* Form chứa textarea và nút submit */}
        <form onSubmit={handleSubmit}>
          {/* Body: Textarea */}
          <div className="mb-6">
            <textarea
              id="declineReason"
              rows={8}
              className="w-full rounded-md border border-gray-300 p-3 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Nhập lý do..."
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              autoFocus // Tự động focus vào textarea khi mở
            />
          </div>

          {/* Footer: Nút "Gửi" */}
          <div className="flex justify-end">
            <button
              type="submit"
              className="rounded-md bg-red-600 px-6 py-2 font-medium text-white shadow-sm transition-colors hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
            >
              Gửi
            </button>
          </div>
        </form>

      </div>
    </div>
  );
}
