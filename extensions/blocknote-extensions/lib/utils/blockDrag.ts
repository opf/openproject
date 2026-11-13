import type { SideMenuExtension } from '@blocknote/core';
import type { DragEvent } from 'react';
import type { AnyEditor } from '../editorTypes';

type SideMenuInstance = NonNullable<ReturnType<ReturnType<typeof SideMenuExtension>>>;

export function blockDragProps(editor:AnyEditor, blockId:string) {
  return {
    draggable: 'true' as const,
    onDragStart: (event:DragEvent) => {
      const sideMenu = editor.extensions.get('sideMenu') as SideMenuInstance | undefined;
      const block = editor.getBlock(blockId);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument
      if (block) sideMenu?.blockDragStart(event.nativeEvent, block as any);
    },
  };
}
