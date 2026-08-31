import { BlockNoteSchema } from '@blocknote/core';
import { BlockNoteView } from '@blocknote/mantine';
import { useCreateBlockNote, SuggestionMenuController, getDefaultReactSlashMenuItems } from '@blocknote/react';
import { filterSuggestionItems } from '@blocknote/core/extensions';
import { useCallback } from 'react';
import { createPortal } from 'react-dom';
import { onTestFinished } from 'vitest';
import { render } from 'vitest-browser-react';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  getOpenProjectSlashMenuItems,
  useHashWpMenu,
  ShadowDomWrapper,
} from '../../lib';

import '@blocknote/core/fonts/inter.css';
import '@blocknote/mantine/style.css';
import mantineStylesUrl from '@blocknote/mantine/style.css?url';

const defaultSchema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

function Editor({ onEditor, schema }:{ onEditor?:(editor:any) => void; schema?:any }) {
  const editor = useCreateBlockNote({ schema: schema ?? defaultSchema });
  onEditor?.(editor);

  const { getHashItems, HashWpMenu } = useHashWpMenu(editor as any);

  const getSlashItems = useCallback(
    async (query:string) =>
      filterSuggestionItems(
        [
          ...getDefaultReactSlashMenuItems(editor),
          ...getOpenProjectSlashMenuItems(editor as any),
        ],
        query
      ),
    [editor]
  );

  return (
    <div style={{ paddingTop: 100, height: 500 }}>
    <BlockNoteView editor={editor} slashMenu={false}>
      <SuggestionMenuController triggerCharacter="/" getItems={getSlashItems} />
      <SuggestionMenuController
        triggerCharacter="#"
        getItems={getHashItems}
        suggestionMenuComponent={HashWpMenu}
      />
    </BlockNoteView>
    </div>
  );
}

export function renderEditor(opts?:{ onEditor?:(editor:any) => void; schema?:any }) {
  return render(<Editor onEditor={opts?.onEditor} schema={opts?.schema} />);
}

export async function renderEditorInShadowDom(opts?:{ onEditor?:(editor:any) => void; schema?:any }) {
  const host = document.createElement('div');
  document.body.appendChild(host);
  onTestFinished(() => host.remove());

  const shadowRoot = host.attachShadow({ mode: 'open' });
  const mount = document.createElement('div');
  shadowRoot.appendChild(mount);

  await new Promise<void>((resolve, reject) => {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = mantineStylesUrl;
    link.onload = () => resolve();
    link.onerror = () => reject(new Error('Failed to load BlockNote styles into the shadow root'));
    shadowRoot.appendChild(link);
  });

  const renderResult = await render(
    createPortal(
      <ShadowDomWrapper target={mount}>
        <Editor onEditor={opts?.onEditor} schema={opts?.schema} />
      </ShadowDomWrapper>,
      mount
    )
  );

  return { renderResult, shadowRoot };
}
