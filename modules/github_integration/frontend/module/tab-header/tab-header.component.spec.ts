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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { TabHeaderComponent } from 'core-app/features/plugins/linked/openproject-github_integration/tab-header/tab-header.component';
import { By } from '@angular/platform-browser';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { GitActionsMenuDirective } from 'core-app/features/plugins/linked/openproject-github_integration/git-actions-menu/git-actions-menu.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';


describe('TabHeaderComponent', () => {
  let component:TabHeaderComponent;
  let fixture:ComponentFixture<TabHeaderComponent>;
  let element:DebugElement;
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };
  let oPContextMenuService:{ show:ReturnType<typeof vi.fn> };
  // @ts-ignore
  window.Mousetrap = () => () => { };

  beforeEach(async () => {
    const oPContextMenuServiceSpy = {
      show: vi.fn().mockName('OPContextMenuService.show')
    };

    await TestBed
      .configureTestingModule({
      declarations: [
        TabHeaderComponent,
        OpIconComponent,
        GitActionsMenuDirective,
      ],
      providers: [
        { provide: I18nService, useValue: I18nServiceStub },
        { provide: OPContextMenuService, useValue: oPContextMenuServiceSpy },
      ],
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TabHeaderComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    oPContextMenuService = fixture.debugElement.injector.get(OPContextMenuService) as unknown as typeof oPContextMenuService;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render title and copy button', () => {
    const headerTitle = fixture.debugElement.query(By.css('h3')).nativeElement;
    const headerCopyButton = fixture.debugElement.query(By.css('button.github-git-copy[gitActionsCopyDropdown]')).nativeElement;

    expect(headerTitle.textContent.trim()).toBe('test translation');
    expect(headerCopyButton).toBeTruthy();
  });
});
