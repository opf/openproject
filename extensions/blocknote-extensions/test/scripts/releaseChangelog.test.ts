import { describe, it, expect } from 'vitest';
import { releaseChangelog } from '../../scripts/releaseChangelog.ts';

const CHANGELOG = `# Changelog

Unreleased changes are collected in changelog/unreleased.

## [0.3.4]

Changes up to and including this version were not recorded.
`;

describe('releaseChangelog', () => {
  it('adds a section for the version above the previous release, grouped and sorted by ticket', () => {
    const released = releaseChangelog(CHANGELOG, '0.3.5', [
      { fileName: 'BNE-200.fixed.md', content: 'Fix the second thing\n' },
      { fileName: 'BNE-99.fixed.md', content: '- Fix the first thing' },
      { fileName: 'BNE-150.added.md', content: 'Add a thing' },
    ]);

    expect(released).toBe(`# Changelog

Unreleased changes are collected in changelog/unreleased.

## [0.3.5]

### Added

- Add a thing ([BNE-150](https://community.openproject.org/wp/BNE-150))

### Fixed

- Fix the first thing ([BNE-99](https://community.openproject.org/wp/BNE-99))
- Fix the second thing ([BNE-200](https://community.openproject.org/wp/BNE-200))

## [0.3.4]

Changes up to and including this version were not recorded.
`);
  });

  it('links only fragments named after a ticket', () => {
    const released = releaseChangelog(CHANGELOG, '0.3.5', [{ fileName: 'blocknote-0.55.changed.md', content: 'Update BlockNote' }]);

    expect(released).toContain('- Update BlockNote\n');
  });

  it('rejects a fragment of an unknown type', () => {
    expect(() => releaseChangelog(CHANGELOG, '0.3.5', [{ fileName: 'BNE-1.bugfix.md', content: 'Fix' }]))
      .toThrow('BNE-1.bugfix.md: expected <ticket>.<type>.md');
  });

  it('rejects a fragment of more than one line', () => {
    expect(() => releaseChangelog(CHANGELOG, '0.3.5', [{ fileName: 'BNE-1.fixed.md', content: 'Fix\n- Fix more' }]))
      .toThrow('BNE-1.fixed.md: expected exactly one line');
  });

  it('refuses a release without entries or one that is already in the changelog', () => {
    expect(() => releaseChangelog(CHANGELOG, '0.3.5', [])).toThrow('no changelog entries');
    expect(() => releaseChangelog(CHANGELOG, '0.3.4', [{ fileName: 'BNE-1.fixed.md', content: 'Fix' }]))
      .toThrow('already has a section for 0.3.4');
  });
});
