// @vitest-environment jsdom
import { describe, expect, it } from 'vitest';
import { canOpenMentionMenu } from '../../../../lib/components/MentionMenu/mentionTrigger';
import {
  createHeadlessEditor,
  createHeadlessEditorWithText,
} from '../../../helpers/headlessEditor';
import { chipContent, mentionContent, textContent } from '../../../helpers/content';

function opensAt(editor:ReturnType<typeof createHeadlessEditor>):boolean {
  return editor.transact((transaction) => canOpenMentionMenu(transaction));
}

function opensAfter(text:string):boolean {
  return opensAt(createHeadlessEditorWithText(text));
}

function opensAfterContent(...content:unknown[]):boolean {
  const editor = createHeadlessEditor(content);
  editor.setTextCursorPosition(editor.document[0], 'end');
  return opensAt(editor);
}

describe('canOpenMentionMenu', () => {
  it('opens at the start of a block', () => expect(opensAfter('')).toBe(true));
  it('opens after a space', () => expect(opensAfter('Thanks ')).toBe(true));
  it('opens after an opening bracket or quote', () => {
    expect(opensAfter('(')).toBe(true);
    expect(opensAfter('"')).toBe(true);
  });
  it('opens after a line break', () => {
    const editor = createHeadlessEditorWithText('line\n');
    expect(editor.prosemirrorState.selection.$from.nodeBefore?.type.name).toBe('hardBreak');
    expect(opensAt(editor)).toBe(true);
  });
  it('stays closed inside a word, e.g. an email address', () => expect(opensAfter('ihor')).toBe(false));
  it('stays closed after punctuation that does not open a phrase', () => expect(opensAfter('a.')).toBe(false));
  it('stays closed directly after an inline node', () => {
    expect(opensAfterContent(textContent('Hi '), mentionContent('7', 'Anna Kovalenko'))).toBe(false);
    expect(opensAfterContent(textContent('See '), chipContent('42'))).toBe(false);
  });
});
