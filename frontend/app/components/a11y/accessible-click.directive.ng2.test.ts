// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, DebugElement} from "@angular/core";

require('core-app/angular4-test-setup');

import {async, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {AccessibleByKeyboardComponent} from 'core-components/a11y/accessible-by-keyboard.component';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {AccessibleClickDirective} from "core-components/a11y/accessible-click.directive";
import {By} from "@angular/platform-browser";

@Component({
  template: `<div (accessibleClick)="onClick()">Click me</div>`
})
class TestAccessibleClickDirective {
  public onClick() {
  }
}

describe('accessibleByKeyboard component', () => {

  beforeEach(async(() => {

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

      const spy = sinon.spy(app, 'onClick');
      fixture.detectChanges();

      // Trigger click
      element.triggerEventHandler('click', {type: 'click'});
      element.triggerEventHandler('keyup', {type: 'keyup', which: 13});
      element.triggerEventHandler('keyup', {type: 'keyup', which: 32});

      tick();
      fixture.detectChanges();
      expect(spy).to.have.been.calledThrice;
    }));
  });
});



