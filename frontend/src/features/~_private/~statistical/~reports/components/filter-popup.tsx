import { XMarkIcon } from '@heroicons/react/24/solid';
import { useState, useEffect } from "react"

// Định nghĩa props cho component, ví dụ prop onClose để đóng popup
interface FilterPopupProps {
  onClose: () => void;
}

// Dữ liệu giả cho các học kỳ
const semesterData = [
  { id: '251', label: '251', checked: true },
  { id: '252', label: '252', checked: true },
  { id: '253', label: '253', checked: true },
  { id: '261', label: '261', checked: true },
  { id: '262', label: '262', checked: false },
  { id: '263', label: '263', checked: false },
];

// Mock dữ liệu cho môn học
const courseData = [
  { id: 'c_math', label: 'Toán cao cấp', checked: true },
  { id: 'c_physics', label: 'Vật lý', checked: true },
  { id: 'c_programming', label: 'Lập trình nâng cao', checked: false },
  { id: 'c_history', label: 'Lịch sử', checked: false },
];

export function FilterPopup({ onClose }: FilterPopupProps) {
  // State quản lý tab đang active
  const [activeTab, setActiveTab] = useState('hocKy'); // 'hocKy' hoặc 'monHoc'

  // State quản lý các checkbox học kỳ
  const [semesters, setSemesters] = useState(() => {
    const initialState: { [key: string]: boolean } = {};
    semesterData.forEach(item => {
      initialState[item.id] = item.checked;
    });
    return initialState;
  });

  // State quản lý radio button ngôn ngữ
  const [language, setLanguage] = useState('en'); // 'en' hoặc 'vi'

  // State quản lý các checkbox môn học
  const [courses, setCourses] = useState(() => {
    const initialState: { [key: string]: boolean } = {};
    courseData.forEach(item => {
      initialState[item.id] = item.checked;
    });
    return initialState;
  });

  // Handler khi thay đổi checkbox môn học
  const handleCourseChange = (id: string) => {
    setCourses(prev => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  // Handler khi thay đổi checkbox
  const handleSemesterChange = (id: string) => {
    setSemesters(prev => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const filterCount = 11;

  // Disable page scroll while popup is open. Restore previous styles on unmount.
  useEffect(() => {
    const previousOverflow = document.body.style.overflow;
    const previousPaddingRight = document.body.style.paddingRight;

    // Hide overflow to prevent scrolling
    document.body.style.overflow = 'hidden';

    // Prevent layout shift by adding padding equal to scrollbar width (if any)
    const scrollBarWidth = window.innerWidth - document.documentElement.clientWidth;
    if (scrollBarWidth > 0) {
      document.body.style.paddingRight = `${scrollBarWidth}px`;
    }

    return () => {
      document.body.style.overflow = previousOverflow;
      document.body.style.paddingRight = previousPaddingRight;
    };
  }, []);

  return (
    // Lớp phủ (overlay)  z
    <div className="fixed inset-0 z-50 mt-12 flex items-start justify-end px-10 py-32" onClick={onClose}>
      {/* Container của popup - đặt ở góc trên phải */}
      <div className="relative flex w-full max-w-sm flex-col rounded-2xl border border-gray-600 bg-gray-50 p-6 shadow-custom-yellow">

        {/* Header: "Filter" và nút X */}
        <div className="flex items-center justify-between pb-4">
          <h2 className="text-2xl font-bold text-gray-900">Filter</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
            aria-label="Close modal"
          >
            <XMarkIcon className="size-6" />
          </button>
        </div>

        {/* Khu vực Tabs */}
        <div className="flex border-b border-gray-200">
          <button
            onClick={() => setActiveTab('hocKy')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === 'hocKy'
                ? 'border-b-2 border-[#0329E9] text-[#0329E9]'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Học kỳ
          </button>
          <button
            onClick={() => setActiveTab('monHoc')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === 'monHoc'
                ? 'border-b-2 border-[#0329E9] text-[#0329E9]'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            Môn học
          </button>
        </div>

        {/* Nội dung Tabs */}
        <div className="py-4">
          {/* Tab Học Kỳ */}
          {activeTab === 'hocKy' && (
            <div className="h-48 overflow-y-auto rounded-lg border border-gray-300 bg-white">
              <div className="flex flex-col">
                {semesterData.map(item => (
                  <label
                    key={item.id}
                    className={`flex cursor-pointer items-center px-4 py-3 transition-colors ${
                      semesters[item.id] ? 'bg-blue-50' : 'hover:bg-gray-50'
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={semesters[item.id]}
                      onChange={() => handleSemesterChange(item.id)}
                      className="size-5 rounded border-gray-300 text-[#0329E9] focus:ring-blue-500"
                    />
                    <span className="ml-3 text-sm text-gray-700">{item.label}</span>
                  </label>
                ))}
              </div>
            </div>
          )}
          {/* Tab Môn Học */}
          {activeTab === 'monHoc' && (
            // Nếu không có môn học nào -> hiển thị dòng 'Không có môn học'
            (courseData.length === 0) ? (
              <div className="flex h-48 items-center justify-center rounded-lg border border-gray-300 bg-white p-4">
                <p className="text-gray-500">Không có môn học</p>
              </div>
            ) : (
              <div className="h-48 overflow-y-auto rounded-lg border border-gray-300 bg-white">
                <div className="flex flex-col">
                  {courseData.map(item => (
                    <label
                      key={item.id}
                      className={`flex cursor-pointer items-center px-4 py-3 transition-colors ${
                        courses[item.id] ? 'bg-blue-50' : 'hover:bg-gray-50'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={courses[item.id]}
                        onChange={() => handleCourseChange(item.id)}
                        className="size-5 rounded border-gray-300 text-[#0329E9] focus:ring-blue-500"
                      />
                      <span className="ml-3 text-sm text-gray-700">{item.label}</span>
                    </label>
                  ))}
                </div>
              </div>
            )
          )}
        </div>

        {/* Khu vực Ngôn ngữ */}
        <div className="mb-4">
          <h3 className="mb-3 text-lg font-semibold text-gray-900">
            Ngôn ngữ
          </h3>
          <div className="flex flex-col rounded-lg border border-gray-300 bg-white">
            <label
              className={`flex cursor-pointer items-center px-4 py-3 transition-colors ${
                language === 'en' ? 'bg-blue-50' : 'hover:bg-gray-50'
              }`}
            >
              <input
                type="radio"
                name="language"
                value="en"
                checked={language === 'en'}
                onChange={() => setLanguage('en')}
                className="size-5 text-[#0329E9] focus:ring-blue-500"
              />
              <span className="ml-3 text-sm text-gray-700">Tiếng Anh</span>
            </label>
            <label
              className={`flex cursor-pointer items-center px-4 py-3 transition-colors ${
                language === 'vi' ? 'bg-blue-50' : 'hover:bg-gray-50'
              }`}
            >
              <input
                type="radio"
                name="language"
                value="vi"
                checked={language === 'vi'}
                onChange={() => setLanguage('vi')}
                className="size-5 text-[#0329E9] focus:ring-blue-500"
              />
              <span className="ml-3 text-sm text-gray-700">Tiếng Việt</span>
            </label>
          </div>
        </div>

        {/* Nút Apply Filter */}
        <div className="mt-auto pt-4">
          <button className="flex w-full items-center justify-between rounded-lg bg-blue-800 px-5 py-3 text-white shadow-md transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
            <span className="text-base font-semibold">Apply Filter</span>
            <span className="flex size-7 items-center justify-center rounded-full bg-white text-sm font-bold text-blue-800">
              {filterCount}
            </span>
          </button>
        </div>

      </div>
    </div>
  );
}
