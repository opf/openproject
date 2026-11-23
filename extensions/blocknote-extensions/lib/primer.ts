import { ActionList, ActionMenu, IconButton, Button, Checkbox, Dialog, FormControl, PortalContext, SegmentedControl, SelectPanel, TextInput, Textarea } from '@primer/react';
import { type PrimerDialogComponents, setPrimerDialogs } from './services/dialogComponents';

export type { FormResourcePickerProps } from './services/dialogComponents';
export type { WorkPackagePickerProps } from './components/WorkPackageAttribute/WorkPackagePicker';

export function enablePrimerDialogs(controls:Pick<PrimerDialogComponents, 'WorkPackagePicker' | 'FormResourcePicker'> = {}) {
  setPrimerDialogs({ ...controls, ActionList, ActionMenu, IconButton, Button, Checkbox, Dialog, FormControl, PortalContext, SegmentedControl, SelectPanel, TextInput, Textarea });
}
