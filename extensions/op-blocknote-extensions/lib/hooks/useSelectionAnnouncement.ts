import { useEffect } from 'react';
import type { RefObject } from 'react';
import { useTranslation } from 'react-i18next';
import type { AnyEditor } from '../editorTypes';
import { isWorkPackageNodeSelected } from '../utils/selection';
import { WorkPackageAccessibilityExtension } from '../plugins/workPackageAccessibilityExtension';

// Announces the work package rendered into `elementRef` each time it becomes
// the node selection, and takes the announcement back once it no longer is.
export function useSelectionAnnouncement(
  elementRef:RefObject<HTMLElement | null>,
  editor:AnyEditor | undefined,
  description:string | undefined,
):void {
  const { t } = useTranslation();
  const message = description && t('options.selectedAnnouncement', { description });

  useEffect(() => {
    if (!editor || !message) return;

    const announcer = editor.getExtension(WorkPackageAccessibilityExtension);
    if (!announcer) return;

    let wasSelected = false;
    const followSelection = () => {
      const selected = isWorkPackageNodeSelected(editor, elementRef.current);
      if (selected && !wasSelected) announcer.announce(message);
      if (!selected && wasSelected) announcer.clearAnnouncement();
      wasSelected = selected;
    };

    const unsubscribe = editor.onSelectionChange(followSelection);
    // The work package may have been selected before there was anything to announce.
    followSelection();
    return unsubscribe;
  }, [editor, elementRef, message]);
}
