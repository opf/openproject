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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { autoScrollForElements } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';

type CleanupFn = () => void;
export type AutoScrollAllowedAxis = 'vertical'|'horizontal'|'all';

// Register auto-scrolling on a scroll container for the duration of a drag.
// The caller supplies `canScroll` (typically a payload-scope check, so only
// drags belonging to that consumer scroll its container). Returns a cleanup
// function to detach it.
export function registerAutoScroll({
  element,
  canScroll,
  axis = 'vertical',
  maxScrollSpeed = 'standard',
}:{
  element:Element;
  canScroll:(args:{ source:{ data:Record<string|symbol, unknown> } }) => boolean;
  axis?:AutoScrollAllowedAxis;
  maxScrollSpeed?:'standard'|'fast';
}):CleanupFn {
  return autoScrollForElements({
    element,
    canScroll,
    getAllowedAxis: () => axis,
    getConfiguration: () => ({ maxScrollSpeed }),
  });
}
