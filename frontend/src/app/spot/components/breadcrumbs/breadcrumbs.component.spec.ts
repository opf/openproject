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
import { By } from '@angular/platform-browser';
import { userEvent } from 'vitest/browser';
import { OpSpotModule } from '../../spot.module';
import { SpotBreadcrumbsComponent } from './breadcrumbs.component';

describe('SpotBreadcrumbsComponent activation', () => {
  beforeEach(() => TestBed.configureTestingModule({ imports: [OpSpotModule] }));

  it('allows a breadcrumb without a navigation callback', () => {
    const fixture = TestBed.createComponent(SpotBreadcrumbsComponent);
    fixture.componentRef.setInput('content', { crumbs: [{ text: 'Parent' }, { text: 'Current' }] });
    fixture.detectChanges();
    expect(() => fixture.debugElement.query(By.css('button')).triggerEventHandler('click', new MouseEvent('click'))).not.toThrow();
  });

  it('keeps a native button and invokes its optional callback once without cancelling activation', () => {
    const fixture = TestBed.createComponent(SpotBreadcrumbsComponent);
    const navigate = vi.fn();
    fixture.componentRef.setInput('content', { crumbs: [{ text: 'Parent', navigate }, { text: 'Current' }] });
    fixture.detectChanges();
    const button:HTMLButtonElement = fixture.debugElement.query(By.css('button')).nativeElement;
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, ctrlKey: true });
    button.dispatchEvent(event);
    expect(button.type).toBe('button');
    expect(navigate).toHaveBeenCalledOnce();
    expect(event.defaultPrevented).toBe(false);
  });

  it.each(['{Enter}', ' '])('preserves native keyboard activation for %s', async (key) => {
    const fixture = TestBed.createComponent(SpotBreadcrumbsComponent);
    const navigate = vi.fn();
    fixture.componentRef.setInput('content', { crumbs: [{ text: 'Parent', navigate }, { text: 'Current' }] });
    fixture.detectChanges();
    const button:HTMLButtonElement = fixture.debugElement.query(By.css('button')).nativeElement;
    button.focus();
    await userEvent.keyboard(key);
    expect(navigate).toHaveBeenCalledOnce();
  });

});
