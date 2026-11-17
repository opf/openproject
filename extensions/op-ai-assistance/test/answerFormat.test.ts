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
import { AnswerFormat, buildActions } from '../src/core/answerFormat';
import { changeOptions } from './helpers';

describe('AnswerFormat', () => {
  const format = new AnswerFormat(changeOptions());

  it('keeps a finding with evidence and takes the area from the changed field', () => {
    const result = format.evaluate({
      text: 'The status is outdated.',
      severity: 'high',
      area: 'none',
      evidence: ['Comment: work has started'],
      changes: [{ field: 'status', value: 'in progress' }],
    });

    expect(result.reason).toBeNull();
    expect(result.proposal).toMatchObject({
      severity: 'high',
      area: 'status',
      evidence: ['Comment: work has started'],
      actions: [{ key: 'status', value: '/api/v3/statuses/7', label: 'In progress' }],
    });
  });

  it('drops a finding without evidence', () => {
    expect(format.evaluate({ text: 'Guess.', severity: 'low', area: 'content', evidence: [' '], changes: [] }))
      .toEqual({ proposal: null, reason: 'no evidence' });
  });

  it('keeps a plain proposal only with a valid change', () => {
    expect(format.evaluate({ text: 'Rename', severity: 'none', area: 'none', evidence: [], changes: [{ field: 'subject', value: 'New' }] }).proposal)
      .toMatchObject({ severity: null, area: null, actions: [{ key: 'subject', value: 'New' }] });
    expect(format.evaluate({ text: 'Nothing', severity: 'none', area: 'none', evidence: [], changes: [] }))
      .toEqual({ proposal: null, reason: 'no valid change' });
  });

  it('limits the change fields in the schema to the allowed keys', () => {
    const readOnly = new AnswerFormat(changeOptions('read_only'));
    const schema = JSON.stringify(readOnly.schema());
    expect(schema).toContain('"enum":["none"]');
  });

  it('sorts by the first changed field, then by area, then by the model order', () => {
    const proposals = [
      { text: 'c', severity: null, area: 'relations', evidence: [], actions: [] },
      { text: 'b', severity: null, area: null, evidence: [], actions: [{ key: 'status' as const, value: 'x', label: 'x' }] },
      { text: 'a', severity: null, area: null, evidence: [], actions: [{ key: 'subject' as const, value: 'x', label: 'x' }] },
      { text: 'd', severity: null, area: 'content', evidence: [], actions: [] },
    ];
    expect(format.sort(proposals).map((proposal) => proposal.text)).toEqual(['a', 'b', 'd', 'c']);
  });
});

describe('buildActions', () => {
  it('drops unknown fields, values that are not allowed, duplicates and values that change nothing', () => {
    const actions = buildActions(changeOptions(), [
      { field: 'status', value: 'New' },
      { field: 'status', value: 'Rejected' },
      { field: 'version', value: '1.0' },
      { field: 'due_date', value: '2026-12-01' },
      { field: 'start_date', value: '2026-02-30' },
      { field: 'priority', value: 'High' },
      { field: 'priority', value: 'Normal' },
      { field: 'comment', value: 'Please check.' },
    ]);

    expect(actions.map((action) => [action.key, action.value])).toEqual([
      ['priority', '/api/v3/priorities/9'],
      ['comment', 'Please check.'],
    ]);
  });

  it('allows only comments in the comment-only scope', () => {
    expect(buildActions(changeOptions('comment_only'), [{ field: 'subject', value: 'x' }, { field: 'comment', value: 'y' }]))
      .toEqual([{ key: 'comment', value: 'y', label: 'y' }]);
  });

  it('allows only the fields that the form allows', () => {
    const options = changeOptions('changes', { writable: ['subject'], choices: {}, current: {} });
    expect(options.keys).toEqual(['subject', 'comment']);
  });
});
