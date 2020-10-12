// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, DebugElement} from "@angular/core";

import {ComponentFixture, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {By} from "@angular/platform-browser";
import {AccessibleClickDirective} from "core-app/modules/a11y/accessible-click.directive";

@Component({
  template: `<div (accessibleClick)="onClick()">Click me</div>`
})
class TestAccessibleClickDirective {
  public onClick() {
  }
}

describe('accessibleByKeyboard component', () => {

  beforeEach((() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        AccessibleClickDirective,
        TestAccessibleClickDirective
      ]
    }).compileComponents();
  }));

  describe('triggering the click handler', () => {
    let app:TestAccessibleClickDirective;
    let fixture:ComponentFixture<TestAccessibleClickDirective>;
    let element:DebugElement;

    it('should render an inner link with specified classes', fakeAsync(() => {
      fixture = TestBed.createComponent(TestAccessibleClickDirective);
      app = fixture.debugElement.componentInstance;
      element = fixture.debugElement.query(By.css('div'));

      const spy = spyOn(app, 'onClick');
      fixture.detectChanges();

      // Trigger click
      const eventBase = { preventDefault: () => undefined, stopPropagation: () => undefined };
      element.triggerEventHandler('click', _.assign({type: 'click' }, eventBase));
      element.triggerEventHandler('keydown', _.assign({type: 'keydown', which: 13}, eventBase));
      element.triggerEventHandler('keydown', _.assign({type: 'keydown', which: 32}, eventBase));

      tick();
      fixture.detectChanges();
      expect(spy).toHaveBeenCalledTimes(3);
    }));
  });
});



