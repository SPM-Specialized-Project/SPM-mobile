import React, { useState, useEffect } from 'react';

import useLockBodyScroll from '@/hooks/use-lock-body-scroll';
import { type Book } from '@/types/book.type';



// --- Props cho Modal ---
type BookDetailsModalProps = {
  book: Book | null; // Sách được chọn để hiển thị
  onClose: () => void; // Hàm để đóng modal
};

// --- [HELPER] Component Icon ---
const ClipboardIcon = (props: React.ComponentProps<'svg'>) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
    strokeWidth={1.5}
    stroke="currentColor"
    {...props}
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75c0-.231-.035-.454-.1-.664M6.75 7.5h10.5a2.25 2.25 0 012.25 2.25v7.5a2.25 2.25 0 01-2.25 2.25H6.75a2.25 2.25 0 01-2.25-2.25v-7.5a2.25 2.25 0 012.25-2.25z"
    />
  </svg>
);

// --- [HELPER] Component Icon ---
const CheckIcon = (props: React.ComponentProps<'svg'>) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
    strokeWidth={3} // Dày hơn để nổi bật
    stroke="currentColor"
    {...props}
  >
    <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
  </svg>
);

// --- [HELPER] Component render các hàng chi tiết ---
const DetailRow = ({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) => (
  <p className="text-sm">
    <span className="font-medium text-gray-600">{label} </span>
    <span className="text-gray-800">{value}</span>
  </p>
);

/**
 * ==========================================================
 * COMPONENT MODAL CHÍNH
 * ==========================================================
 */
export function BookDetailsModal({ book, onClose }: BookDetailsModalProps) {
  const [isCopied, setIsCopied] = useState(false);


  // Lock background scroll khi modal mở
  useLockBodyScroll(!!book);
  // Khi modal đóng/mở hoặc sách thay đổi, reset trạng thái "Đã sao chép"
  useEffect(() => {
    if (book) {
      setIsCopied(false);
    }
  }, [book]);

  // Nếu không có sách, không render gì cả
  if (!book) {
    return null;
  }

  // Tạo link chia sẻ (bạn có thể thay đổi URL)
  // Giả sử URL của bạn là /book/[id]
  const shareUrl = `${window.location.origin}/book/${book.id}`;

  // Hàm xử lý copy
  const handleCopy = () => {
    navigator.clipboard
      .writeText(shareUrl)
      .then(() => {
        setIsCopied(true);
        // Tự động quay lại trạng thái "Sao chép" sau 2 giây
        setTimeout(() => setIsCopied(false), 2000);
      })
      .catch(err => {
        console.error('Không thể sao chép: ', err);
      });
  };

  return (
    // Lớp phủ (Overlay)
    <div
      className="fixed inset-0 z-[500000] flex items-center justify-center bg-black/70"
      onClick={onClose} // Đóng modal khi click ra ngoài
    >
      {/* Khung nội dung Modal */}
      <div
        className="relative m-4 w-full max-w-3xl rounded-lg bg-white p-6 shadow-xl"
        onClick={e => e.stopPropagation()} // Ngăn click bên trong làm đóng modal
      >
        {/* Nút Đóng (X) */}
        <button
          onClick={onClose}
          className="absolute -right-3 -top-3 flex size-8 items-center justify-center rounded-full bg-gray-600 text-white transition hover:bg-red-500"
          aria-label="Đóng"
        >
          <svg
            className="size-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>

        {/* Nội dung chi tiết */}
        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {/* Cột 1: Ảnh bìa (giả) */}
          <div className="flex h-72 w-full items-center justify-center rounded-md bg-gray-100 text-gray-400 md:col-span-1">
            {/* Nếu có book.coverImage thì dùng <img>, nếu không thì dùng placeholder */}
            {book.coverImage ? (
              <img
                src={book.coverImage}
                alt={`Bìa sách ${book.title}`}
                className="size-full rounded-md object-cover"
              />
            ) : (
              <span className="text-gray-500">[Ảnh bìa sách]</span>
            )}
          </div>

          {/* Cột 2: Thông tin chi tiết */}
          <div className="flex flex-col space-y-2 md:col-span-2">
            {/* Trạng thái */}
            <span
              className={`mb-1 w-fit rounded-full px-3 py-0.5 text-sm font-semibold ${
                book?.availability === 'available'
                  ? 'bg-green-100 text-green-800'
                  : book?.availability === 'borrowed'
                  ? 'bg-yellow-100 text-yellow-800'
                  : book?.availability === 'reserved'
                  ? 'bg-blue-100 text-blue-800'
                  : 'bg-red-100 text-red-800'
              }`}
            >
              {book.availability}
            </span>

            {/* Tiêu đề */}
            <h2 className="text-2xl font-bold text-gray-900">{book.title}</h2>

            {/* Các thông tin khác */}
            <DetailRow label="Tác giả:" value={book.author} />
            <DetailRow label="NXB:" value={book.publisher} />
            <DetailRow label="Năm:" value={book.year} />

            {/* Đường kẻ ngang */}
            <hr className="my-3" />

            <DetailRow label="Vị trí:" value={book.location} />
            <DetailRow label="Mã số:" value={book.callNumber} />
          </div>
        </div>

        {/* Phần Chia sẻ & Sao chép */}
        <div className="mt-6">
          <label
            htmlFor="share-link"
            className="block text-sm font-medium text-gray-700"
          >
            Chia sẻ đường dẫn
          </label>
          <div className="mt-1 flex rounded-md shadow-sm">
            <input
              type="text"
              id="share-link"
              readOnly
              value={shareUrl}
              className="block w-full flex-1 rounded-none rounded-l-md border-gray-300 bg-gray-50 px-3 py-2 text-gray-600 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />

            {/* Nút Sao chép (thay đổi linh hoạt) */}
            <button
              onClick={handleCopy}
              className={`relative -ml-px inline-flex items-center space-x-2 rounded-r-md border px-4 py-2 text-sm font-medium transition duration-150 ease-in-out focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 ${
                isCopied
                  ? 'border-green-400 bg-green-50 text-green-700'
                  : 'border-gray-300 bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {isCopied ? (
                <CheckIcon className="size-5 text-green-600" />
              ) : (
                <ClipboardIcon className="size-5 text-gray-500" />
              )}
              <span>{isCopied ? 'Đã chép!' : 'Sao chép'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
