import { describe, it, expect } from 'vitest';
import { ATTRIBUTE_DISPLAYS, normalizeDisplay } from '../../../../lib/components/WorkPackageAttribute/display';

describe('normalizeDisplay', () => {
  it('keeps every display it knows', () => {
    for (const display of ATTRIBUTE_DISPLAYS) expect(normalizeDisplay(display)).toBe(display);
  });

  it('shows the value for anything else', () => {
    expect(normalizeDisplay(undefined)).toBe('value');
    expect(normalizeDisplay('')).toBe('value');
    expect(normalizeDisplay('icon')).toBe('value');
  });
});
