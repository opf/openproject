// @vitest-environment jsdom
import { describe, it, expect, vi } from 'vitest';
import type { AnyEditor } from '../../../lib/editorTypes';
import type { WorkPackage } from '../../../lib/openProjectTypes';
import { createPendingRegistry } from '../../../lib/utils/pending';
import {
  findPendingInline,
  insertPendingInline,
  removePendingInline,
  inPlaceHandlers,
} from '../../../lib/utils/pendingInline';
import { INLINE_WP_TYPE } from '../../../lib/utils/nodeTypes';
import {
  blockContent,
  chipContent,
  createHeadlessEditor,
  createHeadlessEditorWithText,
  nthChipPosition,
  textContent,
} from '../../helpers/headlessEditor';

const workPackage = { id: 7, displayId: 'PROJ-7' } as WorkPackage;

function insertPlaceholder(editor:AnyEditor, { withSpacer = true } = {}) {
  const registry = createPendingRegistry<WorkPackage>();
  let pendingWpid = '';

  insertPendingInline(editor, registry, {
    type: INLINE_WP_TYPE,
    props: { size: 's' },
    withSpacer,
    entry: (wpid) => {
      pendingWpid = wpid;
      return inPlaceHandlers(editor, INLINE_WP_TYPE, wpid, (resolved:WorkPackage) => ({
        wpid: String(resolved.id),
        displayId: resolved.displayId,
      }));
    },
  });

  return { registry, pendingWpid };
}

describe('insertPendingInline', () => {
  it('inserts a registered placeholder followed by a space', () => {
    const editor = createHeadlessEditorWithText('Hello ');

    const { registry, pendingWpid } = insertPlaceholder(editor);

    expect(registry.get(pendingWpid)).toBeDefined();
    expect(blockContent(editor)).toMatchObject([
      { type: 'text', text: 'Hello ' },
      { type: INLINE_WP_TYPE, props: { wpid: pendingWpid, size: 's' } },
      { type: 'text', text: ' ' },
    ]);
  });

  it('leaves the space out on request', () => {
    const editor = createHeadlessEditorWithText('Hello ');

    const { pendingWpid } = insertPlaceholder(editor, { withSpacer: false });

    expect(blockContent(editor)).toMatchObject([
      { type: 'text', text: 'Hello ' },
      { type: INLINE_WP_TYPE, props: { wpid: pendingWpid } },
    ]);
  });

  it('keeps nothing registered when the placeholder cannot be inserted', () => {
    const editor = createHeadlessEditorWithText('Hello ');
    vi.spyOn(editor, 'insertInlineContent').mockImplementation(() => { throw new Error('boom'); });
    vi.spyOn(console, 'error').mockImplementation(() => {});

    const { registry, pendingWpid } = insertPlaceholder(editor);

    expect(registry.get(pendingWpid)).toBeUndefined();
  });
});

describe('inPlaceHandlers', () => {
  it('turns the placeholder into what was picked', () => {
    const editor = createHeadlessEditorWithText('Hello ');
    const { registry, pendingWpid } = insertPlaceholder(editor);

    registry.get(pendingWpid)!.onResolve(workPackage);

    expect(registry.get(pendingWpid)).toBeUndefined();
    expect(blockContent(editor)).toMatchObject([
      { type: 'text', text: 'Hello ' },
      { type: INLINE_WP_TYPE, props: { wpid: '7', displayId: 'PROJ-7', size: 's' } },
      { type: 'text', text: ' ' },
    ]);
  });

  it('takes the placeholder and its space away when cancelled', () => {
    const editor = createHeadlessEditorWithText('Hello ');
    const { registry, pendingWpid } = insertPlaceholder(editor);

    registry.get(pendingWpid)!.onCancel();

    expect(registry.get(pendingWpid)).toBeUndefined();
    expect(blockContent(editor)).toMatchObject([{ type: 'text', text: 'Hello ' }]);
  });
});

describe('removePendingInline', () => {
  it('keeps what follows the placeholder when it is not a space', () => {
    const editor = createHeadlessEditor([textContent('a'), chipContent('pending:x'), textContent('b')]);

    expect(removePendingInline(editor, 'pending:x', INLINE_WP_TYPE, { withSpacer: true })).toBe(true);

    expect(blockContent(editor)).toMatchObject([{ type: 'text', text: 'ab' }]);
  });

  it('says so when the placeholder is gone', () => {
    const editor = createHeadlessEditor([textContent('a')]);

    expect(removePendingInline(editor, 'pending:x', INLINE_WP_TYPE)).toBe(false);
  });
});

describe('findPendingInline', () => {
  it('finds the placeholder with the given pending wpid', () => {
    const editor = createHeadlessEditor([textContent('a'), chipContent('pending:x'), textContent('b')]);

    const found = findPendingInline(editor.prosemirrorState.doc, 'pending:x', INLINE_WP_TYPE);

    expect(found?.node.attrs.wpid).toBe('pending:x');
    expect(found?.position).toBe(nthChipPosition(editor, 0));
  });

  it('finds nothing when no placeholder matches', () => {
    const editor = createHeadlessEditor([textContent('a'), chipContent('1')]);

    expect(findPendingInline(editor.prosemirrorState.doc, 'pending:x', INLINE_WP_TYPE)).toBeNull();
  });

  it('finds nothing for a wpid that is not pending, even if a node carries it', () => {
    const editor = createHeadlessEditor([chipContent('1')]);

    expect(findPendingInline(editor.prosemirrorState.doc, '1', INLINE_WP_TYPE)).toBeNull();
  });

  it('finds nothing of another node type', () => {
    const editor = createHeadlessEditor([chipContent('pending:x')]);

    expect(findPendingInline(editor.prosemirrorState.doc, 'pending:x', 'openProjectWorkPackageAttributeInline')).toBeNull();
  });
});
