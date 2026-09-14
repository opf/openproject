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
import { WorkPackageViewOrderService } from './wp-view-order.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { WorkPackageViewSortByService } from './wp-view-sort-by.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

describe('WorkPackageViewOrderService', () => {
  let service:WorkPackageViewOrderService;
  let querySpace:IsolatedQuerySpace;
  let mockUpdateFn:ReturnType<typeof vi.fn>;

  class CausedUpdatesServiceStub {
    add = vi.fn();
  }

  class WorkPackageViewSortByServiceStub {
    readonly isManualSortingMode = false;
  }

  class PathHelperServiceStub {
  }

  beforeEach(async () => {
    mockUpdateFn = vi.fn().mockResolvedValue(new Date());

    const apiV3ServiceStub = {
      queries: {
        id: vi.fn().mockReturnValue({
          order: {
            update: mockUpdateFn,
            get: vi.fn().mockResolvedValue({}),
          },
        }),
      },
    };

    await TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        { provide: ApiV3Service, useValue: apiV3ServiceStub },
        { provide: CausedUpdatesService, useClass: CausedUpdatesServiceStub },
        { provide: WorkPackageViewSortByService, useClass: WorkPackageViewSortByServiceStub },
        { provide: PathHelperService, useClass: PathHelperServiceStub },
        WorkPackageViewOrderService,
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackageViewOrderService);
    querySpace = TestBed.inject(IsolatedQuerySpace);

    // Initialize a persisted query for testing
    const mockQuery = {
      id: '123',
      _links: { self: { href: 'test' } },
    } as Record<string, unknown>;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-argument
    querySpace.query.putValue(mockQuery as any);
  });

  describe('remove', () => {
    it('returns filtered order synchronously', () => {
      const order = ['1', '2', '3', '4'];
      const wpId = '2';

      const result = service.remove(order, wpId);

      expect(result).toEqual(['1', '3', '4']);
    });

    it('calls update but does not await it', () => {
      const order = ['1', '2', '3'];
      const wpId = '2';

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.spyOn(service as any, 'update');

      service.remove(order, wpId);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      expect((service as any).update).toHaveBeenCalledWith({ [wpId]: -1 });
    });
  });

  describe('move', () => {
    it('rejects an id that is not in the order, without touching it', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, 'gone', 1)).rejects.toThrow('not in the current order');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('rejects an out-of-bounds target index, without touching the order', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, '2', -1)).rejects.toThrow('out of bounds');
      await expect(service.move(order, '2', 3)).rejects.toThrow('out of bounds');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('rejects a target index that is not a whole number', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, '2', NaN)).rejects.toThrow('out of bounds');
      await expect(service.move(order, '2', 1.5)).rejects.toThrow('out of bounds');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('moves the id and persists the new positions', async () => {
      const order = ['1', '2', '3'];

      const result = await service.move(order, '1', 2);

      expect(result).toEqual(['2', '3', '1']);
      expect(mockUpdateFn).toHaveBeenCalled();
    });
  });

  describe('removePersisted', () => {
    it('resolves with filtered order after update resolves', async () => {
      const order = ['1', '2', '3', '4'];
      const wpId = '2';

      const result = await service.removePersisted(order, wpId);

      expect(result).toEqual(['1', '3', '4']);
    });

    it('rejects when update rejects', async () => {
      const order = ['1', '2', '3'];
      const wpId = '2';

      const updateError = new Error('Update failed');
      mockUpdateFn.mockRejectedValueOnce(updateError);

      await expect(service.removePersisted(order, wpId)).rejects.toThrow('Update failed');
    });

    it('filters order the same way as remove', async () => {
      const order = ['1', '2', '3', '4', '5'];
      const wpId = '3';

      const result = await service.removePersisted(order, wpId);

      expect(result).toEqual(['1', '2', '4', '5']);
    });
  });
});
