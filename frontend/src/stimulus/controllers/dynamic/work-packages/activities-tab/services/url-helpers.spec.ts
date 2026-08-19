/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { UrlHelpers, ActivityAnchorType } from './url-helpers';

describe('UrlHelpers', () => {
  describe('extractActivityAnchor', () => {
    it('parses a comment anchor', () => {
      expect(UrlHelpers.extractActivityAnchor('#comment-80'))
        .toEqual({ type: ActivityAnchorType.Comment, id: '80' });
    });

    it('parses an activity anchor', () => {
      expect(UrlHelpers.extractActivityAnchor('#activity-45'))
        .toEqual({ type: ActivityAnchorType.Activity, id: '45' });
    });

    it('returns null for an unrelated hash', () => {
      expect(UrlHelpers.extractActivityAnchor('#section-3')).toBeNull();
    });
  });

  describe('canonicalActivityAnchor', () => {
    it('translates an activity anchor to the resolved comment anchor', () => {
      const activity = { type: ActivityAnchorType.Activity, id: '5' };

      expect(UrlHelpers.canonicalActivityAnchor(activity, 456))
        .toEqual({ type: ActivityAnchorType.Comment, id: '456' });
    });

    it('leaves a comment anchor unchanged', () => {
      const comment = { type: ActivityAnchorType.Comment, id: '456' };

      expect(UrlHelpers.canonicalActivityAnchor(comment, 999)).toEqual(comment);
    });

    it('leaves an activity anchor unchanged when nothing was resolved', () => {
      const activity = { type: ActivityAnchorType.Activity, id: '5' };

      expect(UrlHelpers.canonicalActivityAnchor(activity, null)).toEqual(activity);
      expect(UrlHelpers.canonicalActivityAnchor(activity, 0)).toEqual(activity);
    });
  });
});
