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

import { AccessibleByKeyboardComponent } from "core-app/modules/a11y/accessible-by-keyboard.component";

import { ComponentFixture, TestBed } from '@angular/core/testing';


describe('accessibleByKeyboard component', () => {
  beforeEach((() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        AccessibleByKeyboardComponent
      ]
    }).compileComponents();
  }));

  describe('inner element', function() {
    let app:AccessibleByKeyboardComponent;
    let fixture:ComponentFixture<AccessibleByKeyboardComponent>;
    let element:HTMLElement;

    it('should render an inner link with specified classes', function() {
      fixture = TestBed.createComponent(AccessibleByKeyboardComponent);
      app = fixture.debugElement.componentInstance;
      element = fixture.elementRef.nativeElement;

      app.linkClass = 'a-link-class';
      app.spanClass = 'a-span-class';
      fixture.detectChanges();

      const link = element.querySelector('a')!;
      const span = element.querySelector('a > span')!;
      expect(link.classList.contains('a-link-class')).toBeTruthy();
      expect(span.classList.contains('a-span-class')).toBeTruthy();
    });
  });
});



