import React from 'react'

function SendNotificationToAll  ({isOpen, onClose}: {isOpen: boolean, onClose: () => void}) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div className="w-96 rounded-lg bg-white p-6" onClick={e => e.stopPropagation()}>
        <h2 className="mb-4 text-xl font-bold">Gửi thông báo đến tất cả người dùng</h2>
        <textarea
          className="mb-4 h-32 w-full rounded border border-gray-300 p-2"
          placeholder="Nhập nội dung thông báo..."
        ></textarea>
        <div className="flex justify-end gap-4">
          <button
            onClick={onClose}
            className="rounded bg-gray-300 px-4 py-2 hover:bg-gray-400"
          >
            Hủy
          </button>
          <button
            onClick={() => {
              if (window.confirm('Bạn có chắc chắn muốn gửi thông báo đến tất cả người dùng không?')) {
                alert('Thông báo đã được gửi đến tất cả người dùng.');
              }
              onClose();
            }}
            className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            Gửi
          </button>
        </div>
      </div>
    </div>
  );
}

export default SendNotificationToAll
