import { createFileRoute, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/_private/course/')({
  beforeLoad: () => {
    throw redirect({ to: '/course/$id', params: { id: '1' } });
  },
  component: RouteComponent,
});

function RouteComponent() {}
