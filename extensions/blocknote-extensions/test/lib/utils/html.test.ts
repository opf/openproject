import { describe, expect, it } from 'vitest';
import { escapeHtmlAttribute, escapeHtmlText } from '../../../lib/utils/html';

describe('html escaping', () => {
  it('escapes text so it cannot open a tag', () => {
    expect(escapeHtmlText('A & B <script> "x"')).toBe('A &amp; B &lt;script&gt; "x"');
  });

  it('escapes attribute values so they cannot close the quote', () => {
    expect(escapeHtmlAttribute('A & B <x> "y"')).toBe('A &amp; B &lt;x&gt; &quot;y&quot;');
  });
});
