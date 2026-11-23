import { BlockNoteSchema } from '@blocknote/core';
import { PrimerEditorView } from '../../lib/primer';
import { useCreateBlockNote } from '@blocknote/react';
import { createPortal } from 'react-dom';
import { onTestFinished } from 'vitest';
import { render } from 'vitest-browser-react';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  openProjectWorkPackageAttributeInlineSpec,
  openProjectWorkPackageAttributeBlockSpec,
  ShadowDomWrapper,
} from '../../lib';

import '@blocknote/core/fonts/inter.css';
import '../../src/editor.css';
import editorStyles from '../../src/editor.css?inline';

const defaultSchema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
    openProjectWorkPackageAttributeBlock: openProjectWorkPackageAttributeBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
    openProjectWorkPackageAttributeInline: openProjectWorkPackageAttributeInlineSpec,
  },
});

interface EditorOptions {
  onEditor?:(editor:any) => void;
  schema?:any;
  editable?:boolean;
  initialContent?:any[];
}

function Editor({ onEditor, schema, editable = true, initialContent }:EditorOptions) {
  const editor = useCreateBlockNote({
    schema: schema ?? defaultSchema,
    ...(initialContent ? { initialContent } : {}),
  });
  onEditor?.(editor);

  return (
    <div style={{ paddingTop: 100, height: 500 }}>
      <PrimerEditorView editor={editor} editable={editable} />
    </div>
  );
}

export function renderEditor(opts?:EditorOptions) {
  return render(<Editor {...opts} />);
}

export async function renderEditorInShadowDom(opts?:EditorOptions) {
  const host = document.createElement('div');
  document.body.appendChild(host);
  onTestFinished(() => host.remove());

  const shadowRoot = host.attachShadow({ mode: 'open' });
  const mount = document.createElement('div');
  shadowRoot.appendChild(mount);

  const style = document.createElement('style');
  style.textContent = editorStyles;
  shadowRoot.appendChild(style);

  const renderResult = await render(
    createPortal(
      <ShadowDomWrapper target={mount}>
        <Editor {...opts} />
      </ShadowDomWrapper>,
      mount
    )
  );

  return { renderResult, shadowRoot };
}
