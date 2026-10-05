import { describe, it, expect, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  buildWorkPackageAttributeExternalDOM,
  computeWorkPackageAttributeExternalData,
} from '../../../../lib/components/WorkPackageAttribute/externalHtml';

const props = { wpid: '123', displayId: 'PROJ-123', attribute: 'Content owner', display: 'both' };

interface InlineNode { type:string, props?:Record<string, unknown> }

function attributeProps(editor:{ document:{ content?:InlineNode[] }[] }) {
  return editor.document
    .flatMap((block) => block.content ?? [])
    .filter((node) => node.type === 'openProjectWorkPackageAttribute')
    .map((node) => node.props);
}

function pasteHtml(html:string, plain:string) {
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) throw new Error('No [contenteditable] to paste into');
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  dt.setData('text/plain', plain);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Work package attribute chip', () => {
  it('renders the attribute it references', async () => {
    renderEditor({
      initialContent: [{
        type: 'paragraph',
        content: ['Owner: ', { type: 'openProjectWorkPackageAttribute', props }],
      }],
    });

    await expect.element(page.getByText('Content owner')).toBeVisible();
  });

  it('is recreated from its external HTML', async () => {
    let editor:any;
    renderEditor({ onEditor: (e) => { editor = e; } });
    await userEvent.click(page.getByRole('textbox'));

    const data = computeWorkPackageAttributeExternalData(props)!;
    pasteHtml(buildWorkPackageAttributeExternalDOM(data, document).outerHTML, data.text);

    await vi.waitFor(() => {
      expect(attributeProps(editor)).toEqual([props]);
    });
  });
});
