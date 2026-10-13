import React from 'react';

export const SubmissionIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg width="12" height="15" viewBox="0 0 12 15" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M3.33333 10.8333H8.33333V5.83333H11.6667L5.83333 0L0 5.83333H3.33333V10.8333ZM0 12.5H11.6667V14.1667H0V12.5Z" fill="currentColor" fillOpacity="0.87" />
  </svg>
);

export const NoteIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M16.667 1.6665H3.33366C2.41699 1.6665 1.67533 2.4165 1.67533 3.33317L1.66699 18.3332L5.00033 14.9998H16.667C17.5837 14.9998 18.3337 14.2498 18.3337 13.3332V3.33317C18.3337 2.4165 17.5837 1.6665 16.667 1.6665ZM6.66699 11.6665H5.00033V9.99984H6.66699V11.6665ZM6.66699 9.1665H5.00033V7.49984H6.66699V9.1665ZM6.66699 6.6665H5.00033V4.99984H6.66699V6.6665ZM12.5003 11.6665H8.33366V9.99984H12.5003V11.6665ZM15.0003 9.1665H8.33366V7.49984H15.0003V9.1665ZM15.0003 6.6665H8.33366V4.99984H15.0003V6.6665Z" fill="currentColor" />
  </svg>
);

export const CreateMaterialIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg
    width="15"
    height="15"
    viewBox="0 0 15 15"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={`${className ?? ''} transition-colors duration-150`}
  >
    <path d="M13.3333 0H1.66667C0.741667 0 0 0.75 0 1.66667V13.3333C0 14.25 0.741667 15 1.66667 15H13.3333C14.25 15 15 14.25 15 13.3333V1.66667C15 0.75 14.25 0 13.3333 0ZM11.6667 8.33333H8.33333V11.6667H6.66667V8.33333H3.33333V6.66667H6.66667V3.33333H8.33333V6.66667H11.6667V8.33333Z" fill="currentColor" />
  </svg>
);

export const ReferenceBookIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M15.0007 1.6665H5.00065C4.08398 1.6665 3.33398 2.4165 3.33398 3.33317V16.6665C3.33398 17.5832 4.08398 18.3332 5.00065 18.3332H15.0007C15.9173 18.3332 16.6673 17.5832 16.6673 16.6665V3.33317C16.6673 2.4165 15.9173 1.6665 15.0007 1.6665ZM5.00065 3.33317H9.16732V9.99984L7.08398 8.74984L5.00065 9.99984V3.33317Z" fill="#3D4863" fillOpacity="0.87" />
  </svg>
);

export const CheckCircleIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg width="18" height="22" viewBox="0 0 18 22" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M9 0L0 4V10C0 15.55 3.84 20.74 9 22C14.16 20.74 18 15.55 18 10V4L9 0ZM7 16L3 12L4.41 10.59L7 13.17L13.59 6.58L15 8L7 16Z" fill="#3D4863" />
  </svg>
);

export const FolderIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg width="20" height="16" viewBox="0 0 20 16" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
    <path d="M8 0H2C0.9 0 0.00999999 0.9 0.00999999 2L0 14C0 15.1 0.9 16 2 16H18C19.1 16 20 15.1 20 14V4C20 2.9 19.1 2 18 2H10L8 0Z" fill="#3D4863" />
  </svg>
);
