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

import {
  newWorkPackageCardElement,
  WORK_PACKAGE_CARD_SIZE,
  workPackageCardLink,
  workPackageIdFromCardLink,
  workPackageIdFromText,
} from './work-package-cards';

describe('work package cards on whiteboards', () => {
  const context = { origin: 'https://op.example.com', basePath: '/op' };

  describe('workPackageIdFromText', () => {
    it('recognizes hash references', () => {
      expect(workPackageIdFromText('#123', context)).toBe('123');
      expect(workPackageIdFromText('  #PROJ-42 ', context)).toBe('PROJ-42');
    });

    it('recognizes links to work packages of this instance', () => {
      expect(workPackageIdFromText('https://op.example.com/op/wp/7', context)).toBe('7');
      expect(workPackageIdFromText('https://op.example.com/op/work_packages/8/activity', context)).toBe('8');
      expect(workPackageIdFromText('https://op.example.com/op/projects/demo/work_packages/details/9/overview?tab=x', context)).toBe('9');
      expect(workPackageIdFromText('https://op.example.com/op/projects/demo/work_packages/PROJ-3', context)).toBe('PROJ-3');
    });

    it('ignores everything else', () => {
      expect(workPackageIdFromText('123', context)).toBeNull();
      expect(workPackageIdFromText('#123 and more', context)).toBeNull();
      expect(workPackageIdFromText('https://elsewhere.example.com/op/wp/7', context)).toBeNull();
      expect(workPackageIdFromText('https://op.example.com/wp/7', context)).toBeNull();
      expect(workPackageIdFromText('https://op.example.com/op/projects/demo/boards/1', context)).toBeNull();
      expect(workPackageIdFromText('not a link', context)).toBeNull();
    });
  });

  describe('card links', () => {
    it('round-trips the work package id', () => {
      const link = workPackageCardLink('PROJ-42', context);

      expect(link).toBe('https://op.example.com/op/wp/PROJ-42');
      expect(workPackageIdFromCardLink(link, context)).toBe('PROJ-42');
    });

    it('does not claim other embeddables', () => {
      expect(workPackageIdFromCardLink(null, context)).toBeNull();
      expect(workPackageIdFromCardLink('https://www.youtube.com/watch?v=abc', context)).toBeNull();
      expect(workPackageIdFromCardLink('https://op.example.com/op/wp/7/activity', context)).toBeNull();
    });
  });

  describe('newWorkPackageCardElement', () => {
    it('creates an embeddable that only references the work package', () => {
      const element = newWorkPackageCardElement('123', { x: 500, y: 300 }, context);

      expect(element.type).toBe('embeddable');
      expect(element.link).toBe('https://op.example.com/op/wp/123');
      expect(element.width).toBe(WORK_PACKAGE_CARD_SIZE.width);
      expect(element.height).toBe(WORK_PACKAGE_CARD_SIZE.height);
      expect(element.x).toBe(500 - (WORK_PACKAGE_CARD_SIZE.width / 2));
      expect(element.y).toBe(300 - (WORK_PACKAGE_CARD_SIZE.height / 2));
      expect(element.id).toBeTruthy();
      expect(element.version).toBeGreaterThan(0);
    });
  });
});
