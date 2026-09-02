import { useState } from 'react';
import type { ReactNode } from 'react';
import type { AnyEditor } from '../../editorTypes';
import type { WorkPackage } from '../../openProjectTypes';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { insertWorkPackageChipOverSelection } from '../../utils/inlineChipActions';
import { CreateWorkPackageModal } from '../CreateWorkPackage';
import { CreateWorkPackageButton } from './CreateWorkPackageButton';

export interface CreateWorkPackageFromSelection {
  /** Belongs among the children of BlockNote's `FormattingToolbar`. */
  createWorkPackageButton:ReactNode;
  /** Belongs beside the editor; renders nothing until the button is pressed. */
  createWorkPackageModal:ReactNode;
}

export function useCreateWorkPackageFromSelection(editor:AnyEditor):CreateWorkPackageFromSelection {
  const [subject, setSubject] = useState<string>();
  const isOpen = subject !== undefined;

  // Held closed while the form is up: hosts layer BlockNote's floating UI
  // differently, and the toolbar speaks for a selection about to be written over.
  useSuppressFormattingToolbar(editor, isOpen);

  const close = () => setSubject(undefined);

  const handleCreated = (workPackage:WorkPackage) => {
    close();
    insertWorkPackageChipOverSelection(editor, workPackage);
  };

  return {
    createWorkPackageButton: <CreateWorkPackageButton editor={editor} onOpen={setSubject} />,
    createWorkPackageModal: isOpen ? (
      <CreateWorkPackageModal
        anchorEl={editor.domElement}
        initialSubject={subject}
        onCreated={handleCreated}
        onCancel={close}
      />
    ) : null,
  };
}
