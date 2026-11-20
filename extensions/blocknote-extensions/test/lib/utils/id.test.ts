import { describe, it, expect } from 'vitest';
import { formatWorkPackageId, spokenWorkPackageId } from '../../../lib/utils/id.ts';
import i18n from '../../../lib/services/i18n';

describe('formatWorkPackageId', () => {
  it('prepends # to a purely numeric string', () => {
    expect(formatWorkPackageId('123')).toBe('#123');
    expect(formatWorkPackageId('37')).toBe('#37');
    expect(formatWorkPackageId('1')).toBe('#1');
  });

  it('returns alphanumeric displayId as-is without # prefix', () => {
    expect(formatWorkPackageId('DWPS-1')).toBe('DWPS-1');
    expect(formatWorkPackageId('ABC123')).toBe('ABC123');
    expect(formatWorkPackageId('PROJ-42')).toBe('PROJ-42');
  });
});

describe('spokenWorkPackageId', () => {
  const t = i18n.getFixedT('en');

  it('spells out the dash of a semantic identifier', () => {
    expect(spokenWorkPackageId(t, 'DP-2')).toBe('DP dash 2');
  });

  it('reads a numeric identifier as it is shown', () => {
    expect(spokenWorkPackageId(t, '123')).toBe('#123');
  });
});
