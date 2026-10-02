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

import { type SelectionItem } from 'core-common/batch-selection';
import { DragSession, type DragSessionHost, permittedDestinationsFor } from './drag-session';
import { type DestinationIdentity } from './list-dom';

describe('sortable-lists drag session', () => {
  let root:HTMLElement;
  let items:HTMLElement[];
  const list1:DestinationIdentity = { type: 'work_package', id: '1' };
  const list2:DestinationIdentity = { type: 'work_package', id: '2' };

  function item(id:string, mobility = 'free'):HTMLElement {
    const element = document.createElement('li');
    element.setAttribute('data-sortable-lists--item-id-value', id);
    element.setAttribute('data-sortable-lists--item-type-value', 'work_package');
    element.setAttribute('data-sortable-lists--item-mobility-value', mobility);
    return element;
  }

  function identity(element:HTMLElement):SelectionItem {
    return { type: 'work_package', id: element.getAttribute('data-sortable-lists--item-id-value')! };
  }

  function host(overrides:Partial<DragSessionHost> = {}):DragSessionHost {
    return {
      rootElement: root,
      maxBatchSize: 0,
      prospectiveMembers: vi.fn((element:HTMLElement) => [element]),
      frozenMembers: vi.fn((element:HTMLElement) => [identity(element)]),
      ownedDestinations: vi.fn(() => [list1, list2]),
      liveOwnerDestinationOf: vi.fn(() => list1),
      ...overrides,
    };
  }

  beforeEach(() => {
    root = document.createElement('div');
    root.setAttribute('data-controller', 'sortable-lists');
    items = [item('1'), item('2'), item('3', 'confined')];
    root.append(...items);
    document.body.append(root);
  });

  afterEach(() => {
    document.body.replaceChildren();
  });

  describe('prospective phase', () => {
    it('resolves the members once, in the constructor', () => {
      const prospectiveMembers = vi.fn(() => [items[0], items[1]]);
      const session = new DragSession(host({ prospectiveMembers }), items[0]);

      expect(session.phase).toBe('prospective');
      expect(session.members).toEqual([items[0], items[1]]);
      expect(session.size).toBe(2);
      expect(prospectiveMembers).toHaveBeenCalledTimes(1);
    });

    it('is refused only above a positive cap', () => {
      const prospectiveMembers = () => [items[0], items[1]];

      expect(new DragSession(host({ prospectiveMembers, maxBatchSize: 0 }), items[0]).refused).toBe(false);
      expect(new DragSession(host({ prospectiveMembers, maxBatchSize: 2 }), items[0]).refused).toBe(false);
      expect(new DragSession(host({ prospectiveMembers, maxBatchSize: 1 }), items[0]).refused).toBe(true);
    });

    it('mutates nothing before freeze', () => {
      const frozenMembers = vi.fn(() => null);
      const session = new DragSession(host({ frozenMembers }), items[0]);

      session.permittedDestinations();
      session.ownerDestinationOf(items[1]);

      expect(frozenMembers).not.toHaveBeenCalled();
      expect(root.querySelector('[data-dragging]')).toBeNull();
    });
  });

  describe('permitted destinations', () => {
    it('is null while every member reaches every owned list', () => {
      const session = new DragSession(host({ prospectiveMembers: () => [items[0], items[1]] }), items[0]);

      expect(session.permittedDestinations()).toBeNull();
    });

    it('is pinned to the list a confined member sits in', () => {
      const session = new DragSession(host({ prospectiveMembers: () => [items[0], items[2]] }), items[0]);

      expect(session.permittedDestinations()).toEqual([list1]);
    });

    it('is computed once per session', () => {
      const ownedDestinations = vi.fn(() => [list1, list2]);
      const session = new DragSession(host({ ownedDestinations }), items[0]);

      session.permittedDestinations();
      session.permittedDestinations();

      expect(ownedDestinations).toHaveBeenCalledTimes(1);
    });

    it('permittedDestinationsFor returns the empty set when confined members disagree', () => {
      const other = item('4', 'confined');
      const owners = new Map<HTMLElement, DestinationIdentity>([[items[2], list1], [other, list2]]);

      expect(permittedDestinationsFor([items[2], other], [list1, list2], (element) => owners.get(element) ?? null)).toEqual([]);
    });
  });

  describe('owner memo', () => {
    it('remembers an owner for the session', () => {
      const liveOwnerDestinationOf = vi.fn(() => list1);
      const session = new DragSession(host({ liveOwnerDestinationOf }), items[0]);

      expect(session.ownerDestinationOf(items[1])).toEqual(list1);
      liveOwnerDestinationOf.mockReturnValue(list2);
      expect(session.ownerDestinationOf(items[1])).toEqual(list1);
      expect(liveOwnerDestinationOf).toHaveBeenCalledTimes(1);
    });

    it('remembers a missing owner too', () => {
      const liveOwnerDestinationOf = vi.fn(() => null);
      const session = new DragSession(host({ liveOwnerDestinationOf }), items[0]);

      session.ownerDestinationOf(items[1]);
      session.ownerDestinationOf(items[1]);

      expect(liveOwnerDestinationOf).toHaveBeenCalledTimes(1);
    });

    it('re-reads owners after forgetOwners', () => {
      const liveOwnerDestinationOf = vi.fn(() => list1);
      const session = new DragSession(host({ liveOwnerDestinationOf }), items[0]);

      session.ownerDestinationOf(items[1]);
      liveOwnerDestinationOf.mockReturnValue(list2);
      session.forgetOwners();

      expect(session.ownerDestinationOf(items[1])).toEqual(list2);
    });
  });

  describe('freeze and start', () => {
    it('freezes once and reports the batch size', () => {
      const frozenMembers = vi.fn(() => [identity(items[0]), identity(items[1])]);
      const session = new DragSession(host({ frozenMembers }), items[0]);

      expect(session.freeze()).toBe(2);
      expect(session.freeze()).toBe(2);
      expect(session.phase).toBe('frozen');
      expect(frozenMembers).toHaveBeenCalledTimes(1);
    });

    it('marks every frozen member on start', () => {
      const session = new DragSession(host({ frozenMembers: () => [identity(items[0]), identity(items[1])] }), items[0]);

      session.freeze();
      session.start();

      expect(session.phase).toBe('started');
      expect(items[0]).toHaveAttribute('data-dragging', 'source');
      expect(items[1]).toHaveAttribute('data-dragging', 'source');
      expect(items[2]).not.toHaveAttribute('data-dragging');
    });

    it('freezes first when started unfrozen', () => {
      const frozenMembers = vi.fn(() => [identity(items[0])]);
      const session = new DragSession(host({ frozenMembers }), items[0]);

      session.start();

      expect(frozenMembers).toHaveBeenCalledTimes(1);
      expect(session.phase).toBe('started');
    });

    it('re-marks a stripped member on remark only once started', () => {
      const session = new DragSession(host({ frozenMembers: () => [identity(items[0]), identity(items[1])] }), items[0]);

      session.freeze();
      session.remark();
      expect(items[1]).not.toHaveAttribute('data-dragging');

      session.start();
      items[1].removeAttribute('data-dragging');
      session.remark();
      expect(items[1]).toHaveAttribute('data-dragging', 'source');
    });

    it('marks a replacement element for the same identity', () => {
      const session = new DragSession(host({ frozenMembers: () => [identity(items[0]), identity(items[1])] }), items[0]);
      session.start();

      const replacement = item('2');
      items[1].replaceWith(replacement);
      session.remark();

      expect(replacement).toHaveAttribute('data-dragging', 'source');
    });
  });

  describe('without a batch contract', () => {
    it('reports size one, marks the source only and ends with null', () => {
      const session = new DragSession(host({ frozenMembers: () => null }), items[0]);

      expect(session.freeze()).toBe(1);
      session.start();

      expect(items[0]).toHaveAttribute('data-dragging', 'source');
      expect(root.querySelectorAll('[data-dragging]')).toHaveLength(1);
      expect(session.end()).toBeNull();
    });
  });

  describe('end', () => {
    it('hands out the frozen batch once and clears every mark under the root', () => {
      const batch = [identity(items[0]), identity(items[1])];
      const session = new DragSession(host({ frozenMembers: () => batch }), items[0]);
      session.start();
      items[2].setAttribute('data-dragging', 'source');

      expect(session.end()).toEqual(batch);
      expect(session.phase).toBe('ended');
      expect(root.querySelector('[data-dragging]')).toBeNull();
      expect(session.end()).toBeNull();
    });

    it('is idempotent on a session that never froze', () => {
      const session = new DragSession(host(), items[0]);

      expect(session.end()).toBeNull();
      expect(session.phase).toBe('ended');
      session.start();
      expect(session.phase).toBe('ended');
      expect(root.querySelector('[data-dragging]')).toBeNull();
    });
  });
});
