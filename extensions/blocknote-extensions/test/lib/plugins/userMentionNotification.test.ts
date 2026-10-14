// @vitest-environment jsdom
import { beforeEach, describe, expect, it, onTestFinished, vi } from 'vitest';
import { notifyMentionedUser } from '../../../lib/services/openProjectApi';
import { USER_MENTION_TYPE } from '../../../lib/utils/nodeTypes';
import {
  blockText,
  blockTextWithNodes,
  createCollaborativeHeadlessEditors,
  createHeadlessEditor,
  createHeadlessEditorWithBlocks,
  createHeadlessEditorWithText,
  mountHeadlessEditor,
  nthInlineNodePosition,
  placeCursorAfterText,
} from '../../helpers/headlessEditor';
import { editDocument } from '../../helpers/documentContext';
import { mentionContent, paragraphWith, textContent } from '../../helpers/content';

vi.mock(import('../../../lib/services/openProjectApi'), async (importOriginal) => ({
  ...await importOriginal(),
  notifyMentionedUser: vi.fn(() => Promise.resolve()),
}));

const judith = mentionContent('5', 'Judith Roth');
const peter = mentionContent('8', 'Peter Lang');

describe('UserMentionNotificationExtension', () => {
  beforeEach(() => {
    vi.mocked(notifyMentionedUser).mockClear();
    editDocument(3);
  });

  it('notifies the user an inserted mention mentions', () => {
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith]);

    expect(notifyMentionedUser).toHaveBeenCalledExactlyOnceWith(3, '5');
  });

  it('notifies a user mentioned twice in one insertion once', () => {
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith, ' and again ', judith]);

    expect(notifyMentionedUser).toHaveBeenCalledExactlyOnceWith(3, '5');
  });

  it('notifies each of several users mentioned at once', () => {
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith, ' and ', peter]);

    expect(vi.mocked(notifyMentionedUser).mock.calls).toEqual([[3, '5'], [3, '8']]);
  });

  it('notifies about a duplicated mention', () => {
    const editor = mountHeadlessEditor(createHeadlessEditor([judith, textContent(' and')]));
    const mentionPosition = nthInlineNodePosition(editor, USER_MENTION_TYPE);

    placeCursorAfterText(editor, 'and');
    editor.transact((transaction) => {
      transaction.insert(transaction.selection.from, transaction.doc.nodeAt(mentionPosition)!);
    });

    expect(notifyMentionedUser).toHaveBeenCalledExactlyOnceWith(3, '5');
  });

  it('does not notify again on the edits that follow', () => {
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith]);
    editor.insertInlineContent([' for the review']);
    editor.updateBlock(editor.document[0], { type: 'heading' });

    expect(notifyMentionedUser).toHaveBeenCalledOnce();
  });

  it('does not notify while typing next to a mention', () => {
    const editor = mountHeadlessEditor(createHeadlessEditor([textContent('Thanks '), judith, textContent(' and more')]));

    placeCursorAfterText(editor, 'more');
    editor.insertInlineContent(['!']);

    expect(notifyMentionedUser).not.toHaveBeenCalled();
  });

  it('does not notify about a mention in a moved block', () => {
    const editor = mountHeadlessEditor(createHeadlessEditorWithBlocks([paragraphWith(judith), paragraphWith('Last line')]));

    editor.setTextCursorPosition(editor.document[0], 'end');
    editor.moveBlocksDown();

    expect(editor.document.map((_block, index) => blockText(editor, index))).toEqual(['Last line', '']);
    expect(notifyMentionedUser).not.toHaveBeenCalled();
  });

  it('does not notify about a mention moved within the text', () => {
    const editor = mountHeadlessEditor(createHeadlessEditor([judith, textContent(' and more')]));
    const mentionPosition = nthInlineNodePosition(editor, USER_MENTION_TYPE);

    editor.transact((transaction) => {
      const mention = transaction.doc.nodeAt(mentionPosition)!;
      transaction.delete(mentionPosition, mentionPosition + mention.nodeSize);
      transaction.insert(mentionPosition + ' and'.length, mention);
    });

    expect(blockTextWithNodes(editor)).toEqual(' and[openProjectUserMention] more');
    expect(notifyMentionedUser).not.toHaveBeenCalled();
  });

  it('leaves a mention a collaborator inserted to the collaborator', () => {
    const { editors: [mine, theirs], sync } = createCollaborativeHeadlessEditors();
    theirs.setTextCursorPosition(theirs.document[0], 'end');
    theirs.insertInlineContent([judith]);
    vi.mocked(notifyMentionedUser).mockClear();

    sync();

    expect(blockTextWithNodes(mine)).toEqual('[openProjectUserMention]');
    expect(notifyMentionedUser).not.toHaveBeenCalled();
  });

  it('does not notify without a document', () => {
    editDocument('');
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith]);

    expect(notifyMentionedUser).not.toHaveBeenCalled();
  });

  it('logs a failed notification and goes on editing', async () => {
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    onTestFinished(() => consoleSpy.mockRestore());
    const failure = new Error('Forbidden');
    vi.mocked(notifyMentionedUser).mockRejectedValueOnce(failure);
    const editor = mountHeadlessEditor(createHeadlessEditorWithText('Thanks '));

    editor.insertInlineContent([judith, ' there']);

    expect(blockTextWithNodes(editor)).toEqual('Thanks [openProjectUserMention] there');
    await vi.waitFor(() => expect(consoleSpy)
      .toHaveBeenCalledWith('[user mention] Failed to notify user 5:', failure));
  });
});
