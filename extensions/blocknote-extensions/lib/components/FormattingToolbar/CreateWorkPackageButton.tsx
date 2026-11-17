import { PlusIcon } from '@primer/octicons-react';
import { useComponentsContext, useEditorState } from '@blocknote/react';
import { useTranslation } from 'react-i18next';
import type { AnyEditor } from '../../editorTypes';
import { selectedSubject } from './selectedSubject';
import { useCanCreateWorkPackages } from '../../hooks/useCanCreateWorkPackages';

export interface CreateWorkPackageButtonProps {
  editor:AnyEditor;
  onOpen:(subject:string) => void;
}

export const CreateWorkPackageButton = ({ editor, onOpen }:CreateWorkPackageButtonProps) => {
  const { t } = useTranslation();
  const components = useComponentsContext();
  const subject = useEditorState({ editor, selector: () => selectedSubject(editor) });
  const canCreate = useCanCreateWorkPackages();

  if (!components || !subject || !editor.isEditable || !canCreate) return null;

  const label = t('formattingToolbar.createWorkPackage');

  return (
    <components.FormattingToolbar.Button
      className="bn-button"
      label={label}
      mainTooltip={label}
      icon={<PlusIcon size={18} />}
      onClick={() => onOpen(subject)}
    />
  );
};
