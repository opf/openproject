import type { BlockNoteEditor } from '@blocknote/core';
import { useInlineWpEvents } from './useInlineWpEvents';
import { useDeduplicateInstanceIds } from './useDeduplicateInstanceIds';

export function useOpBlockNoteExtensions(
  editor: BlockNoteEditor<any, any, any>
): void {
  useInlineWpEvents(editor);
  useDeduplicateInstanceIds(editor);
}