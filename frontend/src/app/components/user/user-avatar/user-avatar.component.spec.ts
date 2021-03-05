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

import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { UserAvatarComponent } from "core-components/user/user-avatar/user-avatar.component";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { States } from "core-components/states.service";

describe('UserAvatar component test', () => {
  let app:UserAvatarComponent;
  let fixture:ComponentFixture<UserAvatarComponent>;
  let element:HTMLElement;
  let user:any;

  beforeEach(waitForAsync(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        UserAvatarComponent
      ],
      providers: [
        States,
        APIV3Service,
        PathHelperService
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(UserAvatarComponent);
    app = fixture.debugElement.componentInstance;
    element = fixture.elementRef.nativeElement;
  }));

  describe('Regular initials', () => {
    beforeEach(waitForAsync(() => {
      user = {
        id: 1,
        name: 'First Last',
      };

      app.user = user;
      element.dataset.useFallback = 'true';
      app.ngAfterViewInit();
      fixture.detectChanges();
    }));

    it('should render the fallback avatar', function () {
      const link = element.querySelector('.avatar-default')!;
      expect(link.textContent).toEqual('FL');
    });
  });

  describe('Emoji initials', () => {
    beforeEach(waitForAsync(() => {
      user = {
        id: 1,
        name: "️\uFE0F Foo Bar",
      };

      app.user = user;
      element.dataset.useFallback = 'true';
      app.ngAfterViewInit();
      fixture.detectChanges();
    }));

    it('should render the fallback avatar', function () {
      const link = element.querySelector('.avatar-default')!;
      expect(link.textContent).toEqual('\uFe0F' + 'B');
    });
  });
});
