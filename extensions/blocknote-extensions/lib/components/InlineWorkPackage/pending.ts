import type { AnyEditor } from '../../editorTypes';
import type { WorkPackage } from '../../openProjectTypes';
import { createPendingRegistry } from '../../utils/pending';
import type { PendingHandlers } from '../../utils/pending';
import { insertPendingInline, inPlaceHandlers } from '../../utils/pendingInline';
import { INLINE_WP_TYPE } from '../../utils/nodeTypes';
import type { InlineWpSize, PendingMode } from '../WorkPackage/types';

const PENDING_SIZE:InlineWpSize = 's';

export interface PendingWorkPackage extends PendingHandlers<WorkPackage> {
  // Kept here rather than in the node props, so it never reaches the document.
  mode:PendingMode;
  initialSubject?:string;
}

export const pendingWorkPackages = createPendingRegistry<WorkPackage, PendingWorkPackage>();

export function insertPendingInlineWorkPackage(editor:AnyEditor, mode:PendingMode):void {
  insertPendingInline(editor, pendingWorkPackages, {
    type: INLINE_WP_TYPE,
    props: { size: PENDING_SIZE },
    entry: (pendingWpid) => ({
      ...inPlaceHandlers(editor, INLINE_WP_TYPE, pendingWpid, (workPackage:WorkPackage) => ({
        wpid: String(workPackage.id),
        displayId: workPackage.displayId,
      })),
      mode,
    }),
  });
}
