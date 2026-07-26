import { ReactNode } from 'react';
import AppShell from '@/components/AppShell';

// Wraps all protected admin pages in the sidebar shell + auth guard.
export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AppShell>{children}</AppShell>;
}
