import { formatWorkPackageId, isSemanticWorkPackageId } from './work-package-id-pattern';

describe('isSemanticWorkPackageId', () => {
  it('returns true for semantic identifiers', () => {
    expect(isSemanticWorkPackageId('PROJ-42')).toBe(true);
  });

  it('returns false for numeric identifiers', () => {
    expect(isSemanticWorkPackageId('42')).toBe(false);
  });

  it('returns false for empty input', () => {
    expect(isSemanticWorkPackageId('')).toBe(false);
  });
});

describe('formatWorkPackageId', () => {
  it('returns semantic identifiers as-is (no prefix)', () => {
    expect(formatWorkPackageId('PROJ-42')).toBe('PROJ-42');
  });

  it('prefixes numeric identifiers with #', () => {
    expect(formatWorkPackageId('42')).toBe('#42');
  });

  it('returns empty string for empty input', () => {
    expect(formatWorkPackageId('')).toBe('');
  });
});
