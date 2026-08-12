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
import { Component, DebugElement, Input, ChangeDetectionStrategy } from '@angular/core';
import { GitHubTabComponent } from 'core-app/features/plugins/linked/openproject-github_integration/github-tab/github-tab.component';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  selector: 'tab-header',
  template: '',
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TabHeaderStubComponent {
  @Input() workPackage:WorkPackageResource;
}

@Component({
  selector: 'op-tab-prs',
  template: '',
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TabPrsStubComponent {
  @Input() workPackage:WorkPackageResource;
}

describe('GitHubTabComponent.', () => {
  let component:GitHubTabComponent;
  let fixture:ComponentFixture<GitHubTabComponent>;
  let element:DebugElement;
  const workPackage = { id: 'testId' } as WorkPackageResource;
  const apiV3Base = 'http://www.openproject.com/api/v3/';
  const IPathHelperServiceStub = { api: { v3: { apiV3Base } } };
  const I18nServiceStub = {
    t: function (key:string) {
      return 'test translation';
    }
  };

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
      declarations: [
        GitHubTabComponent,
        TabHeaderStubComponent,
        TabPrsStubComponent,
      ],
      providers: [
        { provide: I18nService, useValue: I18nServiceStub },
        { provide: PathHelperService, useValue: IPathHelperServiceStub },
      ],
    })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GitHubTabComponent);
    component = fixture.componentInstance;
    element = fixture.debugElement;
    component.workPackage = workPackage;

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should render header and pull requests components', () => {
    const tabHeader = fixture.debugElement.query(By.css('tab-header'));
    const tabPrs = fixture.debugElement.query(By.css('op-tab-prs'));

    expect(tabHeader).toBeTruthy();
    expect(tabPrs).toBeTruthy();
  });

  it('should pass the work package to the child components', () => {
    const tabHeader = fixture.debugElement.query(By.directive(TabHeaderStubComponent));
    const tabPrs = fixture.debugElement.query(By.directive(TabPrsStubComponent));

    expect(tabHeader.componentInstance.workPackage).toBe(workPackage);
    expect(tabPrs.componentInstance.workPackage).toBe(workPackage);
  });
});
