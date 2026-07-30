import { describe, it, expect, afterEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { BlockNoteSchema, defaultInlineContentSpecs } from '@blocknote/core';
import { openProjectWorkPackageBlockSpec } from '../../../../lib';
import { renderEditor } from '../../../helpers/renderEditor';
import { worker } from '../../../mocks/browser';

// Simulate pasting a plain text URL by dispatching a ClipboardEvent carrying
// only text/plain data, as a browser does when copying from the address bar.
function pastePlainText(plain:string) {
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) {
    throw new Error('Could not find a [contenteditable] element to dispatch paste on');
  }
  const dt = new DataTransfer();
  dt.setData('text/plain', plain);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Paste work package URL', () => {
  afterEach(() => worker.resetHandlers());

  it('creates a block card when pasting into an empty paragraph', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('http://localhost:3000/wp/123');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('creates an inline chip when pasting into a non-empty paragraph', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));
    await userEvent.type(page.getByRole('textbox'), 'See ');

    pastePlainText('http://localhost:3000/work_packages/456');

    await expect.element(page.getByText('#456')).toBeVisible();
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
  });

  it('creates a block card from a semantic identifier URL', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('http://localhost:3000/projects/DWPS/work_packages/DWPS-1/activity');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
  });

  it('creates an inline chip from a semantic identifier URL', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));
    await userEvent.type(page.getByRole('textbox'), 'See ');

    pastePlainText('http://localhost:3000/wp/DWPS-1');

    await expect.element(page.getByText('DWPS-1')).toBeVisible();
    await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
  });

  it('creates an inline chip and keeps the surrounding text around a bare URL', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('before http://localhost:3000/work_packages/456/activity after');

    await expect.element(page.getByText('#456')).toBeVisible();
    await expect.element(page.getByText('before', { exact: false })).toBeVisible();
    await expect.element(page.getByText('after', { exact: false })).toBeVisible();
    expect(document.querySelector('[data-testid="block-card"]')).toBeNull();
  });

  it('creates an inline chip and keeps the trailing text around a markdown WP link', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('[custom label](http://localhost:3000/work_packages/456) text after');

    await expect.element(page.getByText('#456')).toBeVisible();
    await expect.element(page.getByText('text after', { exact: false })).toBeVisible();
    expect(document.body.textContent).not.toContain('custom label');
  });

  it('keeps foreign URLs as plain text', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('https://example.com/wp/123');

    await expect.element(page.getByText('https://example.com/wp/123')).toBeVisible();
  });

  it('creates a block card and drops the label when pasting a markdown WP link into an empty paragraph', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('[custom label](http://localhost:3000/wp/123)');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    expect(document.body.textContent).not.toContain('custom label');
  });

  it('creates an inline chip and drops the label when pasting a markdown WP link into text', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));
    await userEvent.type(page.getByRole('textbox'), 'See ');

    pastePlainText('[custom label](http://localhost:3000/work_packages/456)');

    await expect.element(page.getByText('#456')).toBeVisible();
    expect(document.body.textContent).not.toContain('custom label');
  });

  // What the user notices about the cursor is where the next keystroke lands, so these
  // assert the reading order of the document rather than the selection.
  it('leaves the cursor after the created block card, not in the line above', async () => {
    renderEditor();
    const textbox = page.getByRole('textbox');
    await userEvent.click(textbox);
    await userEvent.keyboard('before{Enter}');

    pastePlainText('http://localhost:3000/wp/123');
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.keyboard('HERE');

    await expect.element(textbox).toHaveTextContent(/before[\s\S]*#123[\s\S]*HERE/);
  });

  it('leaves the cursor between the created card and a card right below it', async () => {
    let editor!:{
      document:{ id:string }[];
      replaceBlocks:(remove:unknown, insert:unknown) => void;
      setTextCursorPosition:(block:string, placement:string) => void;
    };
    renderEditor({ onEditor: (e) => { editor = e; } });
    const textbox = page.getByRole('textbox');
    await expect.element(textbox).toBeVisible();

    editor.replaceBlocks(editor.document, [
      { type: 'paragraph', content: [] },
      { type: 'openProjectWorkPackageBlock', props: { wpid: 456, displayId: '456', size: 'm' } },
    ]);
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
    editor.setTextCursorPosition(editor.document[0].id, 'start');

    pastePlainText('http://localhost:3000/wp/123');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.keyboard('HERE');

    await expect.element(textbox).toHaveTextContent(/#123[\s\S]*HERE[\s\S]*#456/);
  });

  it('leaves the cursor after the link when the work package cannot be reached', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/GONE-1', () =>
        HttpResponse.json({ message: 'not found' }, { status: 404 })
      )
    );
    renderEditor();
    const textbox = page.getByRole('textbox');
    await userEvent.click(textbox);

    pastePlainText('http://localhost:3000/wp/GONE-1');
    await expect.element(page.getByText('http://localhost:3000/wp/GONE-1')).toBeVisible();

    await userEvent.keyboard('HERE');

    await expect.element(textbox).toHaveTextContent('http://localhost:3000/wp/GONE-1HERE');
    // Typing must not extend the link itself.
    expect(document.querySelector('[contenteditable] a')?.textContent)
      .toBe('http://localhost:3000/wp/GONE-1');
  });

  it('keeps markdown links to foreign URLs untouched', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('[docs](https://example.com/wp/123)');

    await expect.element(page.getByText('docs')).toBeVisible();
  });

  it('falls back to the plain link when the schema lacks the inline WP spec', async () => {
    // Pick text/link explicitly: `create()` reuses the module-global default
    // spec objects and `extend()` mutates them, so after renderEditor's
    // module-level schema was built, defaultInlineContentSpecs already
    // contains openProjectWorkPackageInline.
    const blockOnlySchema = BlockNoteSchema.create({
      inlineContentSpecs: {
        text: defaultInlineContentSpecs.text,
        link: defaultInlineContentSpecs.link,
      },
    }).extend({
      blockSpecs: {
        openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
      },
    });
    renderEditor({ schema: blockOnlySchema });
    await userEvent.click(page.getByRole('textbox'));
    await userEvent.type(page.getByRole('textbox'), 'See ');

    pastePlainText('http://localhost:3000/wp/123');

    await expect.element(page.getByText('http://localhost:3000/wp/123')).toBeVisible();
  });
});
