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

import { syncCaret } from './caret-sync';
import type { CaretPlacement } from './caret-placement';

describe('syncCaret', () => {
  let popover:HTMLElement;
  let anchor:HTMLElement;
  let applied:CaretPlacement[];
  let disconnect:() => void;

  const nextMutation = () => new Promise<void>((resolve) => { queueMicrotask(resolve); });

  beforeEach(() => {
    popover = document.createElement('div');
    popover.setAttribute('popover', 'manual');
    popover.style.cssText = 'position: fixed; width: 100px; height: 60px; margin: 0;';
    anchor = document.createElement('div');
    anchor.style.cssText = 'position: fixed; top: 200px; left: 100px; width: 10px; height: 10px;';
    document.body.append(popover, anchor);
    popover.showPopover();
    applied = [];
    disconnect = syncCaret(popover, () => anchor.getBoundingClientRect(), (caret) => applied.push(caret));
  });

  afterEach(() => {
    disconnect();
    popover.remove();
    anchor.remove();
  });

  it('applies a placement when the popover is repositioned', async () => {
    popover.style.top = '100px';
    popover.style.left = '55px';
    await nextMutation();

    expect(applied).toEqual([{ side: 'bottom', offset: 50 }]);
  });

  it('does not re-apply an unchanged placement', async () => {
    popover.style.top = '100px';
    popover.style.left = '55px';
    await nextMutation();
    popover.style.opacity = '1';
    await nextMutation();

    expect(applied).toHaveLength(1);
  });

  it('applies a new side when the popover moves beside the anchor', async () => {
    popover.style.top = '100px';
    popover.style.left = '55px';
    await nextMutation();
    popover.style.top = '175px';
    popover.style.left = '130px';
    await nextMutation();

    expect(applied[1]).toEqual({ side: 'left', offset: 30 });
  });

  it('ignores writes while the popover is closed', async () => {
    popover.hidePopover();
    popover.style.top = '100px';
    await nextMutation();

    expect(applied).toHaveLength(0);
  });

  it('stops after disconnect', async () => {
    disconnect();
    popover.style.top = '100px';
    popover.style.left = '55px';
    await nextMutation();

    expect(applied).toHaveLength(0);
  });

  it('re-applies the same placement after the popover is closed and reopened', async () => {
    popover.style.top = '100px';
    popover.style.left = '55px';
    await nextMutation();

    popover.hidePopover();
    popover.style.top = '0px';
    await nextMutation();

    popover.showPopover();
    popover.style.top = '100px';
    await nextMutation();

    expect(applied).toEqual([{ side: 'bottom', offset: 50 }, { side: 'bottom', offset: 50 }]);
  });
});
