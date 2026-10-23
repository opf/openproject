import {
  FormattingToolbar,
  FormattingToolbarController,
  getFormattingToolbarItems,
  useBlockNoteEditor,
} from '@blocknote/react';
import { useCreateWorkPackageFromSelection } from './useCreateWorkPackageFromSelection';

export const OpenProjectFormattingToolbar = () => {
  const editor = useBlockNoteEditor();
  const { createWorkPackageButton, createWorkPackageModal } = useCreateWorkPackageFromSelection(editor);

  return (
    <>
      <FormattingToolbarController
        formattingToolbar={() => (
          <FormattingToolbar>
            {getFormattingToolbarItems()}
            {createWorkPackageButton}
          </FormattingToolbar>
        )}
      />
      {createWorkPackageModal}
    </>
  );
};
