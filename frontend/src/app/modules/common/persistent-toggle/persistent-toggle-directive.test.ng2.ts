//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

/*jshint expr: true*/
import {PersistentToggleDirective} from "core-app/modules/common/persistent-toggle/persistent-toggle.directive";

require('core-app/angular4-test-setup');

import {async, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {By} from "@angular/platform-browser";
import {AccessibleClickDirective} from "core-app/modules/a11y/accessible-click.directive";
import {Component, DebugElement} from "@angular/core";

@Component({
  template: `
    <persistent-toggle identifier="test.foobar">
      <a class="persistent-toggle--click-handler"></a>
      <div class="persistent-toggle--notification"></div>
    </persistent-toggle>
  `
})
class PersistentToggleDirectiveTest {
}

describe('persistentToggle directive', () => {
  let app:PersistentToggleDirectiveTest;
  let fixture:ComponentFixture<PersistentToggleDirectiveTest>;
  let element:DebugElement;
  const identifier = 'test.foobar';

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        PersistentToggleDirective,
        PersistentToggleDirectiveTest,
      ]
    }).compileComponents();
  }));

  describe('persistentToggle Directive', function() {
    let mockStorage:any = {};
    let button:any, notification:any, getItemStub:any, setItemStub:any;

    describe('toggle property', function() {
      beforeEach(() => {
        fixture = TestBed.createComponent(PersistentToggleDirectiveTest);
        app = fixture.debugElement.componentInstance;
        element = fixture.debugElement;

        getItemStub = sinon.stub(window.localStorage, 'getItem', (key:string) => mockStorage[key]);
        setItemStub = sinon.stub(window.localStorage, 'setItem', (key:string, value:any) => mockStorage[key] = value.toString());

        button = element.query(By.css('.persistent-toggle--click-handler'));
        notification = element.query(By.css('.persistent-toggle--notification'));
      });

      afterEach(function() {
        getItemStub.restore();
        setItemStub.restore();
      });

      it('shows when no value is set', function() {
        var value = (window as any).OpenProject.guardedLocalStorage(identifier);
        expect(value).to.not.be.ok;
        expect(notification.prop('hidden')).to.be.false;
      });

      it('persists the notification status when clicked', function() {
        button.click();

        expect(notification.prop('hidden')).to.be.true;
        var value = (window as any).OpenProject.guardedLocalStorage(identifier);
        expect(value).to.equal('true');
      });
    });
  });
});
