import { Link, useNavigate } from '@tanstack/react-router';
import { useState, useEffect } from 'react';
import { toast } from 'react-toastify';

import {
  Next,
  NotificationIcon,
  ProfileIcon,
  SidebarToggleIcon,
  SignOut,
} from '@/components/icons';
import ChatPopup from '@/components/study-layout/chat-popup';
import NotificationPopup, { subscribeNotifications, getNotificationsStore } from '@/components/study-layout/notification-popup';
// import vndFormat from '@/helpers/currency-format';
import handleAxiosError from '@/helpers/handle-axios-error';
import { useAuthStore } from '@/stores';
// import { useUserStore } from '@/stores';
import { User } from '@/types';
import storage from '@/utils/storage';

import SendNotificationToAll from './send-notification-to-all';

type HeaderProps = {
  user: User | null;
  setUser: (user: User | null) => void;
  toggleSidebarMobile: () => void;
  toggleSidebarDesktop: () => void;
};

const Header = ({
  user,
  setUser,
  toggleSidebarDesktop,
  toggleSidebarMobile,
}: HeaderProps) => {
  const { logout: authLogout, isAuthenticated } = useAuthStore();

  const [dropdownOpened, setDropdownOpened] = useState(false);
  const [notificationOpened, setNotificationOpened] = useState(false);
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [chatOpened, setChatOpened] = useState(false);
  const [loading, setLoading] = useState(false);
  const [openPopupSendNotification, setOpenPopupSendNotification] = useState(false);
  const navigate = useNavigate();

  // subscribe to notification store so badge count stays in sync
  useEffect(() => {
    try {
      // initialize
      const init = getNotificationsStore();
      setUnreadCount(init.filter((i) => !i.isRead).length);
      const unsub = subscribeNotifications((items: any[]) => {
        setUnreadCount(items.filter((i) => !i.isRead).length);
      });
      return () => unsub();
    } catch {
      // ignore subscription errors
      return () => { };
    }
  }, []);

  const logout = async () => {
    try {
      setLoading(true);
      // await AuthService.logout();

      // Use store's logout to clear auth state
      authLogout();

      // Clear any legacy token storage
      storage.removeItem('token');

      // Clear user state
      setUser(null);

      navigate({ to: '/login' });
    } catch (error: unknown) {
      handleAxiosError(error, (message: string) => {
        toast.error(message);
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      id="study-layout-header"
      className="sticky top-0 z-[98] flex h-20 w-full flex-row items-center border-b border-solid border-tertiary-300 bg-white p-5 shadow-for-header 3xl:h-24 3xl:px-10"
    >
      <SidebarToggleIcon
        onClick={toggleSidebarMobile}
        className="relative flex size-8 cursor-pointer fill-tertiary xl:hidden"
      />
      <SidebarToggleIcon
        onClick={toggleSidebarDesktop}
        className="relative hidden size-8 cursor-pointer fill-tertiary xl:flex"
      />
      <div className="flex flex-1" />
      {isAuthenticated ? (
        <>
          {/* Sticky chat activator (provided SVG) */}
          {!chatOpened && (
            <button
              title="Chat"
              onClick={() => setChatOpened(true)}
              className="fixed right-0 top-20 z-[97] p-2 focus:outline-none"
              aria-label="Open chat"
            >
              <svg width="52" height="40" viewBox="0 0 52 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M20 0.5H79.5V39.5H20C9.23045 39.5 0.5 30.7696 0.5 20C0.5 9.23045 9.23045 0.5 20 0.5Z" fill="white" stroke="#3D4863" />
                <path d="M37 14H35V23H22V25C22 25.55 22.45 26 23 26H34L38 30V15C38 14.45 37.55 14 37 14ZM33 20V11C33 10.45 32.55 10 32 10H19C18.45 10 18 10.45 18 11V25L22 21H32C32.55 21 33 20.55 33 20Z" fill="#595959" />
              </svg>
            </button>
          )}
          {/* Notification/Chat Icon */}
          <div
            className="relative mr-4 flex size-10 cursor-pointer items-center justify-center rounded-full border border-gray-300 text-gray-600 transition-colors hover:bg-gray-100 hover:text-[#0329E9]"
            onClick={() => setNotificationOpened(!notificationOpened)}
            title="Notifications"
          >
            <NotificationIcon className="size-6" />
            {/* Badge for unread notifications (optional) */}
            {unreadCount > 0 && (
              <span className="absolute -right-1 -top-1 flex size-5 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">
                {unreadCount}
              </span>
            )}
          </div>
          {user?.isCoordinator && (
            <button
              onClick={() => setOpenPopupSendNotification(true)}
              aria-label="Gửi thông báo"
              className="relative mr-4 flex items-center gap-2 rounded-lg bg-[#0329E9] px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-[#0226b8] md:px-6 3xl:px-8 3xl:text-base"
            >
              <NotificationIcon className="size-4 fill-white" />
              <span>Gửi thông báo</span>
            </button>
          )}

          <div
            className="relative flex size-10 cursor-pointer items-center justify-center rounded-full border-[0.5px] border-solid border-tertiary p-1 xl:h-12 xl:w-80 xl:justify-between"
            onClick={() => setDropdownOpened(!dropdownOpened)}
          >
            <div className="flex h-full flex-row items-center gap-2">
              <div
                style={{ backgroundImage: `url(${user?.picture})` }}
                className={`${user?.picture ? '' : 'flex items-center justify-center bg-tertiary'} relative size-8 rounded-full bg-cover xl:size-10`}
              >
                {user?.picture ? (
                  <></>
                ) : (
                  <ProfileIcon className="size-5 fill-white" />
                )}
              </div>
              <div className="relative hidden flex-col justify-center py-2 xl:flex">
                <span className="select-none text-[14px] font-bold">
                  {user?.firstName || user?.lastName
                    ? `${user?.lastName} ${user?.firstName}`
                    : '[TÊN CHƯA CẬP NHẬT]'}
                </span>
                <span className="select-none text-[12px] text-tertiary-300">
                  {user?.email}
                </span>
              </div>
            </div>
            <Next
              className={`${dropdownOpened ? 'rotate-180' : ''} mr-4 hidden size-4 fill-tertiary xl:flex`}
            />
          </div>
          <div
            className={`${dropdownOpened ? 'flex' : 'hidden'} absolute right-5 top-[4.5rem] z-[99] h-28 w-40 flex-col rounded-lg bg-white shadow-[0_8px_16px_0_rgba(0,0,0,0.25)] xl:w-80`}
          >
            <Link
              to="/profile"
              className="relative flex h-14 w-full flex-row items-center gap-2 rounded-lg px-2 duration-200 ease-in-out hover:bg-tertiary-300"
            >
              <ProfileIcon className="relative size-6 fill-tertiary" />
              <span className="select-none">Hồ sơ cá nhân</span>
            </Link>
            <div
              onClick={async () => {
                if (loading) return;
                await logout();
              }}
              className="relative flex h-14 w-full cursor-pointer flex-row items-center gap-2 rounded-lg px-2 text-red-600 duration-200 ease-in-out hover:bg-red-300"
            >
              <SignOut className="relative size-6" />
              <span className="select-none">Đăng xuất</span>
            </div>
          </div>
        </>
      ) : (
        <Link
          to="/login"
          className="relative flex items-center justify-center rounded-lg bg-primary px-4 py-2 text-xl font-bold text-white duration-200 ease-in-out hover:bg-primary-700 md:px-6 3xl:px-8 3xl:text-2xl"
        >
          {' '}
          Đăng nhập
        </Link>
      )}

      {/* Notification Popup */}
      <NotificationPopup isOpen={notificationOpened} onClose={() => setNotificationOpened(false)} />
      {/* Chat Popup (activated by sticky SVG button) */}
      <ChatPopup isOpen={chatOpened} onClose={() => setChatOpened(false)} />
      {/* Send Notification Popup */}
      <SendNotificationToAll isOpen={openPopupSendNotification} onClose={() => setOpenPopupSendNotification(false)} />
    </div>
  );
};

export default Header;
