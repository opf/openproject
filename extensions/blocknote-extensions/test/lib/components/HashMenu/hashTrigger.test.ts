// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import {
  canOpenHashMenu,
  hashTargetFor,
  MAX_TRIGGER_HASHES,
} from '../../../../lib/components/HashMenu/hashTrigger';
import type { HashTarget } from '../../../../lib/components/HashMenu/hashTrigger';
import {
  chipContent,
  createHeadlessEditor,
  createHeadlessEditorWithText,
  textContent,
} from '../../../helpers/headlessEditor';

function targetFor(blockText:string, query:string):HashTarget {
  return hashTargetFor(createHeadlessEditorWithText(blockText), query);
}

describe('hashTargetFor', () => {
  it('maps a hash run to an inline chip size', () => {
    expect(targetFor('#bug', 'bug')).toEqual({ kind: 'inline', size: 'xxs' });
    expect(targetFor('##bug', 'bug')).toEqual({ kind: 'inline', size: 'xs' });
    expect(targetFor('###bug', 'bug')).toEqual({ kind: 'inline', size: 's' });
  });

  it('maps four hashes to a block card', () => {
    expect(targetFor('####bug', 'bug')).toEqual({ kind: 'block', size: 'm' });
  });

  it('resolves to none for a longer run — the hashes stay literal', () => {
    expect(targetFor('#####bug', '#bug')).toEqual({ kind: 'none' });
    expect(targetFor('######bug', '##bug')).toEqual({ kind: 'none' });
  });

  it('resolves to none when no hash precedes the query', () => {
    expect(targetFor('bug', 'bug')).toEqual({ kind: 'none' });
  });

  it('counts only the run directly before the query', () => {
    expect(targetFor('Hello ####bug', 'bug')).toEqual({ kind: 'block', size: 'm' });
    expect(targetFor('#42 ##bug', 'bug')).toEqual({ kind: 'inline', size: 'xs' });
    expect(targetFor('#### #bug', 'bug')).toEqual({ kind: 'inline', size: 'xxs' });
  });

  it('does not join runs separated by an inline chip', () => {
    const editor = createHeadlessEditor([
      textContent('##'),
      chipContent('1', 'xxs'),
      textContent('##bug'),
    ]);
    editor.setTextCursorPosition(editor.document[0], 'end');

    expect(hashTargetFor(editor, 'bug')).toEqual({ kind: 'inline', size: 'xs' });
  });
});

describe('canOpenHashMenu', () => {
  function canOpenNextHashAfter(standingText:string):boolean {
    const editor = createHeadlessEditorWithText(standingText);
    return canOpenHashMenu(editor.prosemirrorState.tr);
  }

  it('opens for every hash up to and including the one that means a block card', () => {
    expect(canOpenNextHashAfter('')).toBe(true);
    expect(canOpenNextHashAfter('Hello ')).toBe(true);
    expect(canOpenNextHashAfter('#')).toBe(true);
    expect(canOpenNextHashAfter('##')).toBe(true);
    expect(canOpenNextHashAfter('###')).toBe(true);
  });

  it('refuses the hash that would grow the run past the longest supported one', () => {
    expect(canOpenNextHashAfter('#'.repeat(MAX_TRIGGER_HASHES))).toBe(false);
    expect(canOpenNextHashAfter('#'.repeat(MAX_TRIGGER_HASHES + 1))).toBe(false);
  });

  it('starts over after a non-hash character', () => {
    expect(canOpenNextHashAfter('#### ')).toBe(true);
  });
});
