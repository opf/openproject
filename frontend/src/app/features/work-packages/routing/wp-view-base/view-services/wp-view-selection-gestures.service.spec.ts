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
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewSelectionService } from './wp-view-selection.service';
import { WorkPackageViewSelectionGesturesService } from './wp-view-selection-gestures.service';

describe('WorkPackageViewSelectionGesturesService', () => {
  let gestures:WorkPackageViewSelectionGesturesService;
  let selection:WorkPackageViewSelectionService;

  const rendered:RenderedWorkPackage[] = ['1', '2', '3', '4'].map((id) => ({
    classIdentifier: `wp-row-${id}`,
    workPackageId: id,
    hidden: false,
  }));
  const selected = () => selection.getSelectedWorkPackageIds().sort();

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        WorkPackageViewSelectionService,
        WorkPackageViewSelectionGesturesService,
        { provide: OPContextMenuService, useValue: { close: () => undefined } },
      ],
    });
    gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    selection = TestBed.inject(WorkPackageViewSelectionService);
  });

  describe('#click', () => {
    it('replaces the selection on a plain click and returns the ids', () => {
      gestures.click('1', rendered, {});
      const ids = gestures.click('3', rendered, {});

      expect(ids).toEqual(['3']);
      expect(selected()).toEqual(['3']);
    });

    it('ranges from the anchor on shift', () => {
      gestures.click('2', rendered, {});
      gestures.click('4', rendered, { shiftKey: true });

      expect(selected()).toEqual(['2', '3', '4']);
    });

    it('keeps the anchor at the first selected row across shift clicks', () => {
      gestures.click('2', rendered, {});
      gestures.click('4', rendered, { shiftKey: true });
      gestures.click('1', rendered, { shiftKey: true });

      expect(selected()).toEqual(['1', '2']);
    });

    it('toggles with ctrl and with meta', () => {
      gestures.click('1', rendered, {});
      gestures.click('3', rendered, { ctrlKey: true });
      expect(selected()).toEqual(['1', '3']);

      gestures.click('1', rendered, { metaKey: true });
      expect(selected()).toEqual(['3']);
    });

    it('ranges first and then toggles when shift and ctrl are both held', () => {
      gestures.click('1', rendered, {});
      gestures.click('3', rendered, { shiftKey: true, ctrlKey: true });

      expect(selected()).toEqual(['1', '2']);
    });
  });

  describe('#contextMenu', () => {
    it('keeps a selection that contains the work package', () => {
      gestures.click('1', rendered, {});
      gestures.click('3', rendered, { ctrlKey: true });
      gestures.contextMenu('3', rendered);

      expect(selected()).toEqual(['1', '3']);
    });

    it('replaces a selection that does not contain the work package', () => {
      gestures.click('1', rendered, {});
      gestures.contextMenu('4', rendered);

      expect(selected()).toEqual(['4']);
    });

    it('anchors a following shift range at the right-clicked row', () => {
      gestures.contextMenu('2', rendered);
      gestures.click('4', rendered, { shiftKey: true });

      expect(selected()).toEqual(['2', '3', '4']);
    });
  });

  describe('#collapseTo', () => {
    it('collapses a wider selection to the picked-up work package', () => {
      gestures.click('1', rendered, {});
      gestures.click('3', rendered, { ctrlKey: true });
      gestures.collapseTo('3', rendered);

      expect(selected()).toEqual(['3']);
    });

    it('leaves a sole selection and an empty selection alone', () => {
      gestures.collapseTo('2', rendered);
      expect(selected()).toEqual([]);

      gestures.click('2', rendered, {});
      gestures.collapseTo('2', rendered);
      expect(selected()).toEqual(['2']);
    });
  });

  it('#replace selects exactly one work package', () => {
    gestures.click('1', rendered, {});
    gestures.click('3', rendered, { ctrlKey: true });
    gestures.replace('4', rendered);

    expect(selected()).toEqual(['4']);
  });
});
