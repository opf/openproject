import type { ComponentType } from 'react';
import type { WorkPackagePickerProps } from '../components/WorkPackageAttribute/WorkPackagePicker';

export type FormResourcePickerProps = import('../components/CreateWorkPackage/ProjectPicker').ProjectPickerProps & {
  resource:'project' | 'assignee';
};

export type PrimerDialogComponents = Pick<typeof import('@primer/react'),
  'ActionMenu' | 'ActionList' | 'IconButton' | 'Button' | 'Checkbox' | 'Dialog' | 'FormControl' | 'PortalContext' | 'SegmentedControl' | 'SelectPanel' | 'TextInput' | 'Textarea'> & {
  FormResourcePicker?:ComponentType<FormResourcePickerProps>;
  WorkPackagePicker?:ComponentType<WorkPackagePickerProps>;
};

let primerDialogs:PrimerDialogComponents | undefined;

export const getPrimerDialogs = () => primerDialogs;

export function setPrimerDialogs(components?:PrimerDialogComponents) {
  primerDialogs = components;
}
