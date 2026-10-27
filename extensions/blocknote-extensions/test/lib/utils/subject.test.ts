import { describe, it, expect } from 'vitest';
import { subjectOf } from '../../../lib/utils/subject';

describe('subjectOf', () => {
  it('takes the text as it reads', () => {
    expect(subjectOf('Redesign the landing page')).toBe('Redesign the landing page');
  });

  it('leaves the whitespace at the edges of the text behind', () => {
    expect(subjectOf('  Redesign the landing page \n')).toBe('Redesign the landing page');
  });

  it('reads text spanning several lines as one', () => {
    expect(subjectOf('Redesign the landing page\nand the footer')).toBe('Redesign the landing page and the footer');
  });

  it('holds no run of whitespace a subject cannot show', () => {
    expect(subjectOf('Redesign\t\tthe   landing page')).toBe('Redesign the landing page');
  });

  it('has nothing to say about text without words', () => {
    expect(subjectOf('  \n ')).toBe('');
  });
});
