import { describe, it, expect } from 'vitest';
import { formatWorkPackageId, projectIdFromHref } from '../../../lib/utils/id.ts';

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
describe('projectIdFromHref', () => {
  it('reads the id of a project', () => {
    expect(projectIdFromHref('/api/v3/projects/12')).toBe('12');
  });

  it('reads the id of a program, a portfolio and a workspace', () => {
    expect(projectIdFromHref('/api/v3/programs/7')).toBe('7');
    expect(projectIdFromHref('/api/v3/portfolios/11')).toBe('11');
    expect(projectIdFromHref('/api/v3/workspaces/3')).toBe('3');
  });

  it('reads the id of a link below the project', () => {
    expect(projectIdFromHref('/api/v3/portfolios/11/available_assignees?pageSize=1')).toBe('11');
  });

  it('reads no id of a link to something else', () => {
    expect(projectIdFromHref('/api/v3/users/5')).toBeUndefined();
    expect(projectIdFromHref(undefined)).toBeUndefined();
  });
});
