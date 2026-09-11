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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewSelectionService } from './wp-view-selection.service';
import { WorkPackageViewSelectionGesturesService } from './wp-view-selection-gestures.service';

describe('WorkPackageViewSelectionService', () => {
  let selection:WorkPackageViewSelectionService;
  let gestures:WorkPackageViewSelectionGesturesService;
  let querySpace:IsolatedQuerySpace;
  const rows:RenderedWorkPackage[] = ['1', '2', '3', '4'].map((id) => ({
    workPackageId: id, classIdentifier: `wp-row-${id}`, hidden: false,
  }));

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [
      States,
      IsolatedQuerySpace,
      WorkPackageViewSelectionService,
      WorkPackageViewSelectionGesturesService,
      { provide: OPContextMenuService, useValue: { close: () => undefined } },
    ] });
    selection = TestBed.inject(WorkPackageViewSelectionService);
    gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    querySpace.tableRendered.putValue(rows);
  });

  it('keeps the legacy ID order rather than selection insertion order', () => {
    selection.initializeSelection(['10', '2']);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '10']);
  });
  it('accepts calendar selection without a rendered anchor', () => {
    selection.setSelection('2', -1);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
    gestures.click('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['4']);
  });

  it('projects live membership immediately without exposing mutable membership', () => {
    const emissions:{ projected:string[], members:string[] }[] = [];
    const subscription = selection.live$().subscribe(({ selected }) => {
      emissions.push({ projected: Object.keys(selected), members: selection.getSelectedWorkPackageIds() });
      selected['1'] = true;
      delete selected['2'];
    });
    selection.update({ selected: { '1': false, '2': true } });
    expect(emissions.at(-1)).toEqual({ projected: ['2'], members: ['2'] });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
    expect(selection.selectionCount).toBe(1);
    subscription.unsubscribe();
  });

  it('clears stale ranges when importing initialization membership', () => {
    gestures.click('1', rows, {});
    gestures.click('4', rows, { shiftKey: true });
    selection.initializeSelection(['2']);
    gestures.click('3', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['3']);
  });

  it.each(['reset', 'clear'] as const)('does not resurrect pristine members after %s', (operation) => {
    selection.initializeSelection(['1']);
    selection.setRowState('2', true);
    if (operation === 'clear') selection.clear('query changed');
    else selection.reset();
    expect(selection.getSelectedWorkPackageIds()).toEqual([]);
    expect(selection.isEmpty).toBe(true);
    selection.initialize({} as QueryResource, {} as WorkPackageCollectionResource);
    const snapshots:string[][] = [];
    const subscription = selection.live$().subscribe(({ selected }) => snapshots.push(Object.keys(selected)));
    expect(snapshots.every((ids) => ids.length === 0)).toBe(true);
    selection.toggleRow('3');
    expect(selection.getSelectedWorkPackageIds()).toEqual(['3']);
    subscription.unsubscribe();
  });

  it('projects registered resources in legacy ID order', () => {
    const states = TestBed.inject(States);
    const two = { id: '2' } as WorkPackageResource;
    const ten = { id: '10' } as WorkPackageResource;
    states.workPackages.get('2').putValue(two);
    states.workPackages.get('10').putValue(ten);
    selection.initializeSelection(['10', '2']);
    expect(selection.getSelectedWorkPackages()).toEqual([two, ten]);
  });

  it('preserves membership when the query initializes', () => {
    selection.initializeSelection(['2']);
    const snapshots:string[][] = [];
    selection.live$().subscribe(({ selected }) => snapshots.push(Object.keys(selected)));
    selection.initialize({} as QueryResource, {} as WorkPackageCollectionResource);
    expect(snapshots).toEqual([['2'], ['2']]);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  it('selects all with the requested occurrence as the range anchor', () => {
    selection.selectAll(rows, rows[1]);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3', '4']);
    selection.rangeTo(rows[2], rows);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '3']);
  });

  it('falls back to the first selectable occurrence for select all', () => {
    const header:RenderedWorkPackage = { workPackageId: null, classIdentifier: 'group', hidden: false };
    selection.selectAll([header, ...rows], { ...rows[3], classIdentifier: 'missing' });
    selection.rangeTo(rows[1], [header, ...rows]);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
  });

  it('ignores group headers and missing gesture occurrences', () => {
    const header:RenderedWorkPackage = { workPackageId: null, classIdentifier: 'group', hidden: false };
    selection.replaceOccurrence(rows[1]);
    selection.replaceOccurrence(header);
    selection.toggleOccurrence(header);
    selection.rangeTo(header, [header, ...rows]);
    selection.selectAll([header]);
    gestures.click('2', rows, { ctrlKey: true }, rows[0].classIdentifier);
    gestures.replace('5', rows);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  it('includes hidden rows and deduplicates work packages within a range', () => {
    const rendered = [rows[0], { ...rows[1], hidden: true }, { ...rows[1], classIdentifier: 'relation-2' }, rows[2]];
    selection.replaceOccurrence(rendered[0]);
    selection.rangeTo(rendered[3], rendered);
    expect(selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
  });

  it('clears model membership on destruction without publishing', () => {
    selection.initializeSelection(['2']);
    const emitted = vi.fn();
    selection.live$().subscribe(emitted);
    emitted.mockClear();
    selection.ngOnDestroy();
    expect(selection.isEmpty).toBe(true);
    expect(emitted).not.toHaveBeenCalled();
  });

});
