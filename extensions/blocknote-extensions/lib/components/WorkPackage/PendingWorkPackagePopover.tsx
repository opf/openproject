import { useEffect, useState } from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import { WorkPackageSearchPopover } from '../Search/WorkPackageSearchPopover';
import { CreateWorkPackageModal } from '../CreateWorkPackage';
import type { PendingMode } from './types';

interface PendingWorkPackagePopoverProps {
  mode:PendingMode;
  initialSubject?:string;
  anchorEl:HTMLElement;
  onResolve:(workPackage:WorkPackage) => void;
  onCancel:() => void;
}

/**
 * Asks for the work package a pending chip or block stands for: one to link, or
 * one to create. The search hands over to the form in place, so a work package
 * created from it lands where the search was opened.
 */
export const PendingWorkPackagePopover = ({
  mode,
  initialSubject = '',
  anchorEl,
  onResolve,
  onCancel,
}:PendingWorkPackagePopoverProps) => {
  const [subjectToCreate, setSubjectToCreate] = useState(mode === 'create' ? initialSubject : undefined);

  // A reload or a closed tab never blurs the search, and the placeholder would stay in the shared document (BNE-181).
  useEffect(() => {
    window.addEventListener('pagehide', onCancel);
    return () => window.removeEventListener('pagehide', onCancel);
  }, [onCancel]);

  if (subjectToCreate === undefined) {
    return (
      <WorkPackageSearchPopover
        anchorEl={anchorEl}
        onSelect={onResolve}
        onCancel={onCancel}
        onCreate={setSubjectToCreate}
      />
    );
  }

  return (
    <CreateWorkPackageModal
      anchorEl={anchorEl}
      initialSubject={subjectToCreate}
      onCreated={onResolve}
      onCancel={onCancel}
    />
  );
};
