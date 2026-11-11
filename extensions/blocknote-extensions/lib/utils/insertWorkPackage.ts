import type { AnyEditor } from '../editorTypes';
import type { WorkPackage } from '../openProjectTypes';
import type { BlockWpSize, InlineWpSize } from '../components/WorkPackage/types';
import { fullySelectedParagraphIds } from './blockContent';
import { placeCursorAfterBlock } from './cursor';
import { chipContentOf } from './inlineChipActions';
import type { ChipContent } from './inlineChipActions';
import { BLOCK_WP_TYPE } from './nodeTypes';

const BLOCK_WP_SIZE:BlockWpSize = 'm';
const INLINE_WP_SIZE:InlineWpSize = 's';

interface TextContent {
  type:'text';
  text:string;
  styles:Record<string, unknown>;
}

export function insertWorkPackageOverSelection(editor:AnyEditor, workPackage:WorkPackage):void {
  const paragraphIds = fullySelectedParagraphIds(editor);

  if (paragraphIds.length > 0) insertBlockWorkPackage(editor, paragraphIds, workPackage);
  else insertInlineWorkPackage(editor, workPackage);

  editor.focus();
}

function insertBlockWorkPackage(editor:AnyEditor, blockIds:string[], workPackage:WorkPackage):void {
  const block = {
    type: BLOCK_WP_TYPE,
    props: { wpid: workPackage.id, size: BLOCK_WP_SIZE, displayId: workPackage.displayId },
  } as Parameters<AnyEditor['insertBlocks']>[0][number];

  editor.transact(() => {
    const [inserted] = editor.replaceBlocks(blockIds, [block]).insertedBlocks;
    if (inserted) placeCursorAfterBlock(editor, inserted.id);
  });
}

function insertInlineWorkPackage(editor:AnyEditor, workPackage:WorkPackage):void {
  const content:(ChipContent | TextContent)[] = [chipContentOf(workPackage, INLINE_WP_SIZE)];
  if (!spaceFollowsSelection(editor)) content.push({ type: 'text', text: ' ', styles: {} });

  (editor.insertInlineContent as (content:unknown[]) => void)(content);
}

function spaceFollowsSelection(editor:AnyEditor):boolean {
  const { doc, selection } = editor.prosemirrorState;
  return doc.textBetween(selection.to, Math.min(selection.to + 1, doc.content.size)) === ' ';
}
