import { Play as PlayIcon } from '@/components/icons';
import { Paper as PaperIcon } from '@/components/icons';
import BookIcon from '@/components/icons/book';
import LinkIcon from '@/components/icons/link';

import { NoteIcon, ReferenceBookIcon, SubmissionIcon } from './course-icons';

export const typeToIconMap: Record<string, React.ComponentType<{ className?: string }>> = {
  introduction: BookIcon,
  material: PaperIcon,
  movie: PlayIcon,
  note: NoteIcon,
  reference: LinkIcon,
  submission: SubmissionIcon,
  bookReference: ReferenceBookIcon,
};

export const categoryTypes: Array<{ id: string; label: string }> = [
  { id: 'material', label: 'Tài liệu' },
  { id: 'movie', label: 'Bản ghi hình' },
  { id: 'reference', label: 'Đường dẫn' },
  { id: 'note', label: 'Ghi chú' },
  { id: 'bookReference', label: 'Sách tham khảo' },
  { id: 'submission', label: 'Nộp bài' },
  { id: 'introduction', label: 'Giới thiệu' },
];
