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

import { TestBed } from '@angular/core/testing';
import { PersistentToggleComponent } from './persistent-toggle.component';

describe('PersistentToggleComponent', () => {
  it('restores the persisted visibility of its sibling notification', async () => {
    TestBed.configureTestingModule({ declarations: [PersistentToggleComponent] });
    const fixture = TestBed.createComponent(PersistentToggleComponent);
    const element = fixture.nativeElement as HTMLElement;
    element.dataset.identifier = 'persistent-toggle-spec';
    const notification = document.createElement('div');
    notification.className = 'persistent-toggle--toaster';
    element.parentElement!.append(notification);
    const storage = vi.fn().mockReturnValue('true');
    vi.stubGlobal('OpenProject', { guardedLocalStorage: storage });
    try {
      await fixture.whenStable();
      expect(notification.hidden).toBe(true);
      expect(storage).toHaveBeenCalledWith('persistent-toggle-spec');
    } finally {
      notification.remove();
      vi.unstubAllGlobals();
    }
  });
});
