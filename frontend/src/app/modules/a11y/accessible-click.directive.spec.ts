//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { Component, DebugElement } from "@angular/core";

import { ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { By } from "@angular/platform-browser";
import { AccessibleClickDirective } from "core-app/modules/a11y/accessible-click.directive";

@Component({
  template: `<div (accessibleClick)="onClick()">Click me</div>`
})
class TestAccessibleClickDirective {
  public onClick() {
  }
}

@Component({
  template: `<div (accessibleClick)="onClick()" [accessibleClickSkipModifiers]="true">Click me</div>`
})
class TestAccessibleClickDirectiveSkippedModifiers {
  public onClick() {
  }
}

describe('accessibleByKeyboard component', () => {

  beforeEach((() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        AccessibleClickDirective,
        TestAccessibleClickDirective,
        TestAccessibleClickDirectiveSkippedModifiers
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
      element.triggerEventHandler('click', new MouseEvent('click', { ctrlKey: true }));
      element.triggerEventHandler('click', new MouseEvent('click', { ctrlKey: false }));
      element.triggerEventHandler('keydown',new KeyboardEvent('keydown', { key: ' ' }));

      tick();
      fixture.detectChanges();
      expect(spy).toHaveBeenCalledTimes(3);
    }));

    it('allows to disable click handling with modifiers', fakeAsync(() => {
      fixture = TestBed.createComponent(TestAccessibleClickDirectiveSkippedModifiers);
      app = fixture.debugElement.componentInstance;
      element = fixture.debugElement.query(By.css('div'));

      const spy = spyOn(app, 'onClick');
      fixture.detectChanges();

      // Trigger click
      element.triggerEventHandler('click', new MouseEvent('click', { ctrlKey: true }));
      element.triggerEventHandler('click', new MouseEvent('click', { ctrlKey: false }));
      element.triggerEventHandler('keydown',new KeyboardEvent('keydown', { key: ' ' }));

      tick();
      fixture.detectChanges();
      expect(spy).toHaveBeenCalledTimes(2);
    }));
  });
});



