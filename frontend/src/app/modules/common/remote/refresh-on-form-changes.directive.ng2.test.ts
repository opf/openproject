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
import {async, TestBed} from '@angular/core/testing';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {By} from "@angular/platform-browser";
import {RefreshOnFormChangesDirective} from "core-app/modules/common/remote/refresh-on-form-changes.directive";

require('core-app/angular4-test-setup');

@Component({
  template: `
    <form id="foobar">
      <refresh-on-form-changes url="/foo/bar" input-selector="#myval">
        <input type="hidden" name="foo" value="bar"/>
        <input type="text" id="myval" name="foo2"/>
      </refresh-on-form-changes>
    </form>
  `
})
class TestRefreshOnFormChanges {
}

describe('RefreshOnFormChanges directive', () => {

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        RefreshOnFormChangesDirective,
        TestRefreshOnFormChanges
      ]
    }).compileComponents();
  }));

  describe('refreshing the form', () => {
    let app:TestRefreshOnFormChanges;
    let fixture:ComponentFixture<TestRefreshOnFormChanges>;
    let element:DebugElement;

    it('should request the given url on input', () => {
      fixture = TestBed.createComponent(TestRefreshOnFormChanges);
      app = fixture.debugElement.componentInstance;
      element = fixture.debugElement.query(By.css('input'));

      jQuery(element).val('asdf').trigger('change');
      fixture.detectChanges();

      expect(window.location).to.eql('/foo/bar?foo=bar&foo2=asdf');
    });
  });
});



