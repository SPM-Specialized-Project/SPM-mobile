# Frontend content reused by the Flutter app

This file records the source and limits of the material copied from
`C:\disk D\SPM-frontend\frontend`.

| Mobile use | Frontend source | Notes |
| --- | --- | --- |
| App name: `Tutor Support System` | `index.html` and login screen | Product identity shown by the current frontend. |
| Bách Khoa logo | `public/bachkhoa.png` | Copied to `assets/branding/bachkhoa.png`; the public and source asset copies had the same SHA-256. |
| Primary color `#0329E9` | Repeated in frontend screens and inline SVG | Kept as the Flutter theme seed/primary color. |
| Course-card backgrounds | `src/assets/bg-dashboard-{blue,red,green}.png` | Copied into `assets/course_cards/`. |
| Example course titles and codes | `src/components/data/~mock-courses.ts` | Only three examples are shown. They are for UI practice, not live or authoritative course data. |
| Module labels | `src/components/study-layout/sidebar-navigation.tsx` | The five common sidebar labels are included. Role-restricted links are not implied to be available to every user. |

The Flutter gallery intentionally does not copy mock student names, emails,
instructor records, or the `image.png` library-loading graphic. It also does
not port React/TSX icon components or the frontend's remotely loaded fonts.
Course cards are presentation examples; the `/api/courses` endpoint needs the
backend's authenticated API flow before it can supply real user-specific data.
