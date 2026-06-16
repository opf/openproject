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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DebugElement } from '@angular/core';
import { GitLabActionsMenuComponent } from './git-actions-menu.component';
import { GitActionsService } from '../git-actions/git-actions.service';
import { By } from '@angular/platform-browser';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpContextMenuLocalsToken } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

describe('GitLabActionsMenuComponent', () => {
  let component:GitLabActionsMenuComponent;
  let fixture:ComponentFixture<GitLabActionsMenuComponent>;
  let element:DebugElement;
  let gitActionsService:{ gitCommand:ReturnType<typeof vi.fn>; commitMessage:ReturnType<typeof vi.fn>; commitMessageDisplayText:ReturnType<typeof vi.fn>; branchName:ReturnType<typeof vi.fn> };
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };
  const localsStub = {
    workPackage: 1,
    items: [
      {
        hidden: false,
        disabled: false,
        href: 'http://www.google.com',
        linkText: 'linkText',
      }
    ]
  };

  beforeEach(async () => {
    const gitActionsServiceSpy = {
      gitCommand: vi.fn().mockName('GitActionsService.gitCommand'),
      commitMessage: vi.fn().mockName('GitActionsService.commitMessage'),
      branchName: vi.fn().mockName('GitActionsService.branchName')
    };

    await TestBed
      .configureTestingModule({
        declarations: [
          GitLabActionsMenuComponent,
          OpIconComponent,
        ],
        providers: [
          { provide: I18nService, useValue: I18nServiceStub },
          { provide: OpContextMenuLocalsToken, useValue: localsStub },
          { provide: GitActionsService, useValue: gitActionsServiceSpy },
        ],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GitLabActionsMenuComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    gitActionsService = fixture.debugElement.injector.get(GitActionsService) as unknown as typeof gitActionsService;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should generate the branch name on copy button click', () => {
    const copyButton = fixture.debugElement.query(By.css('.copy-button')).nativeElement;

    gitActionsService.branchName.mockReturnValue('test branch');
    copyButton.click();

    fixture.detectChanges();

    expect(gitActionsService.branchName).toHaveBeenCalled();
  });
});
