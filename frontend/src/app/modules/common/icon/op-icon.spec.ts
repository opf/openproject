//-- copyright
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
//++

import {async, ComponentFixture, TestBed} from "@angular/core/testing";
import {OpIcon} from "core-app/modules/common/icon/op-icon";
import {By} from "@angular/platform-browser";
import {DebugElement} from "@angular/core";

describe('opIcon Directive', function() {
  let app:OpIcon;
  let fixture:ComponentFixture<OpIcon>;
  let element:DebugElement;

  beforeEach(async(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        OpIcon
      ]
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OpIcon);
    app = fixture.debugElement.componentInstance;
    element = fixture.debugElement;

    app.iconClasses = 'icon-foobar icon-context';
    fixture.detectChanges();
  });

  describe('without a title', function() {
    it('should render an icon', function () {
      const i = element.query(By.css('i'));

      expect(i.nativeElement.tagName.toLowerCase()).toEqual('i');
      expect(i.classes['icon-foobar']).toBeTruthy();
      expect(i.classes['icon-context']).toBeTruthy();

      expect(element.query(By.css('span'))).toBeNull();
    });
  });

  describe('with a title', function() {
    beforeEach(function() {
      app.iconTitle = 'blabla';
      fixture.detectChanges();
    });

    it('should render icon and title', function() {
      const i = element.query(By.css('i'));
      const span = element.query(By.css('span'));

      expect(i.nativeElement.tagName.toLowerCase()).toEqual('i');
      expect(i.classes['icon-foobar']).toBeTruthy();
      expect(i.classes['icon-context']).toBeTruthy();

      expect(span.nativeElement.tagName.toLowerCase()).toEqual('span');
      expect(span.nativeElement.textContent).toEqual('blabla');
    });
  });
});
