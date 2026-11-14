//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { describe, expect, it } from 'vitest';
import { workPackageIdFrom } from '../src/content/pageInfo';
import { hostsFrom, isTrustedOrigin, originPattern, sameOrigin } from '../src/shared/hosts';
import { parseSkillImport } from '../src/pages/skillImport';

describe('workPackageIdFrom', () => {
  it('reads the full view and the split view', () => {
    expect(workPackageIdFrom('/projects/demo/work_packages/42/activity', 'full')).toBe('42');
    expect(workPackageIdFrom('/work_packages/PROJ-7', 'full')).toBe('PROJ-7');
    expect(workPackageIdFrom('/projects/demo/work_packages/details/13/overview', 'split')).toBe('13');
    expect(workPackageIdFrom('/projects/demo/work_packages', 'full')).toBeNull();
    expect(workPackageIdFrom('/projects/demo/work_packages/details/13/overview', 'full')).toBeNull();
  });
});

describe('originPattern', () => {
  it('leaves out the port and the path', () => {
    expect(originPattern('http://localhost:3000/openproject')).toBe('http://localhost/*');
    expect(originPattern('https://op.example.com')).toBe('https://op.example.com/*');
  });
});

describe('hostsFrom', () => {
  it('keeps the OpenProject hosts and drops broad patterns and LLM hosts', () => {
    expect(hostsFrom([
      'https://*/*',
      'https://op.example.com/*',
      'https://api.anthropic.com/*',
      'https://llm.example.com/*',
    ], 'https://llm.example.com/v1')).toEqual(['https://op.example.com/*']);
  });

  it('keeps an instance that shares its host with the LLM server', () => {
    expect(hostsFrom(['http://localhost/*'], 'http://localhost:11434/v1', 'http://localhost:3000')).toEqual(['http://localhost/*']);
  });
});

describe('isTrustedOrigin', () => {
  const granted = ['https://*/*', 'https://op.example.com/*', 'https://api.anthropic.com/*'];

  it('trusts only an origin that the user granted as an OpenProject host', () => {
    expect(isTrustedOrigin('https://op.example.com', granted)).toBe(true);
    expect(isTrustedOrigin('http://localhost:3000', ['http://localhost/*'])).toBe(true);
    expect(isTrustedOrigin('https://evil.example', granted)).toBe(false);
    expect(isTrustedOrigin('https://api.anthropic.com', granted)).toBe(false);
    expect(isTrustedOrigin('https://op.example.com/path', granted)).toBe(false);
    expect(isTrustedOrigin('not a url', granted)).toBe(false);
    expect(isTrustedOrigin(null, granted)).toBe(false);
  });
});

describe('sameOrigin', () => {
  it('compares the origin of a sender URL', () => {
    expect(sameOrigin('https://op.example.com/work_packages/1', 'https://op.example.com')).toBe(true);
    expect(sameOrigin('https://op.example.com.evil.example/', 'https://op.example.com')).toBe(false);
    expect(sameOrigin(undefined, 'https://op.example.com')).toBe(false);
  });
});

describe('parseSkillImport', () => {
  it('fills safe defaults and rejects files without skills', () => {
    const { skills, instructions } = parseSkillImport(JSON.stringify({
      instructions: 'Help.',
      skills: [{ label: 'Plan', prompt: 'Write a plan.', scope: 'admin', extra: true }],
    }));
    expect(instructions).toBe('Help.');
    expect(skills[0]).toMatchObject({ label: 'Plan', scope: 'read_only', answersAtOnce: false, useTools: true });
    expect(() => parseSkillImport('{}')).toThrow('no "skills" list');
    expect(() => parseSkillImport('nope')).toThrow('not valid JSON');
  });
});
