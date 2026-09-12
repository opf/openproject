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

import { caretPlacement } from './project-timeline-tooltip-caret';

describe('caretPlacement', () => {
  const rect = (left:number, top:number, width:number, height:number) => new DOMRect(left, top, width, height);
  const anchor = rect(100, 100, 10, 10);

  it('puts the caret on the bottom edge, centred on the anchor, when the popover is above', () => {
    expect(caretPlacement(rect(55, 20, 100, 60), anchor)).toEqual({ side: 'bottom', offset: 50 });
  });

  it('puts the caret on the top edge when the popover is below', () => {
    expect(caretPlacement(rect(55, 130, 100, 60), anchor)).toEqual({ side: 'top', offset: 50 });
  });

  it('puts the caret on the left edge when the popover is to the right', () => {
    expect(caretPlacement(rect(130, 75, 100, 60), anchor)).toEqual({ side: 'left', offset: 30 });
  });

  it('puts the caret on the right edge when the popover is to the left', () => {
    expect(caretPlacement(rect(0, 75, 80, 60), anchor)).toEqual({ side: 'right', offset: 30 });
  });

  it('keeps the caret clear of the rounded corners when the popover is shifted sideways', () => {
    expect(caretPlacement(rect(100, 20, 100, 60), anchor).offset).toBe(12);
    expect(caretPlacement(rect(10, 20, 100, 60), anchor).offset).toBe(88);
  });
});
