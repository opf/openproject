import { describe, it, expect } from 'vitest';
import { formatWorkPackageId } from '../../../lib/utils/id.ts';

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