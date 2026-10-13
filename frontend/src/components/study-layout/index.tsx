import { ReactNode, useState, useEffect } from 'react';

import ScrollToTop from '@/components/scroll-to-top';
import { useUserStore } from '@/stores';

// import CountdownBar from '../countdown-bar';

import Footer from './footer';
import Header from './header';
import SidebarDesktop from './sidebar-desktop';
import SidebarMobile from './sidebar-mobile';

type StudyLayoutProps = {
  children: ReactNode;
};

const StudyLayout = ({ children }: StudyLayoutProps) => {
  const { user, setUser } = useUserStore();
  const [sidebarMobileOpened, setSidebarMobileOpened] = useState(false);

  // Initialize sidebar state from localStorage, default to true
  const [sidebarDesktopOpened, setSidebarDesktopOpened] = useState(() => {
    const saved = localStorage.getItem('sidebarDesktopOpened');
    return saved !== null ? saved === 'true' : true;
  });

  // Persist sidebar state to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('sidebarDesktopOpened', String(sidebarDesktopOpened));
  }, [sidebarDesktopOpened]);

  return (
    <>
      <div className="relative flex min-h-screen w-screen min-w-[360px] flex-row bg-white">
        <ScrollToTop />
        <SidebarMobile
          isManager={user?.isManager}
          opened={sidebarMobileOpened}
          close={() => setSidebarMobileOpened(false)}
        />
        <SidebarDesktop
          isManager={user?.isManager}
          opened={sidebarDesktopOpened}
        />
        <div className="relative flex min-h-screen w-full min-w-0 flex-col bg-white">
          <Header
            user={user}
            setUser={setUser}
            toggleSidebarMobile={() =>
              setSidebarMobileOpened(!sidebarMobileOpened)
            }
            toggleSidebarDesktop={() =>
              setSidebarDesktopOpened(!sidebarDesktopOpened)
            }
          />
          {/* <CountdownBar /> */}
          <div className="relative flex flex-col p-5 3xl:p-10">{children}</div>
        </div>
      </div>
      <Footer />
    </>
  );
};

export default StudyLayout;
