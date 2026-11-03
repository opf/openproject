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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { NgxGalleryModule } from '@kolkov/ngx-gallery';
import { BehaviorSubject, of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { ViewerBridgeService } from '../bcf-viewer-bridge/viewer-bridge.service';
import { BcfAuthorizationService } from '../api/bcf-authorization.service';
import { ViewpointsService } from '../helper/viewpoints.service';
import { BcfWpAttributeGroupComponent } from './bcf-wp-attribute-group.component';
import { BcfNewWpAttributeGroupComponent } from './bcf-new-wp-attribute-group.component';

import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('BCF attribute group save integration', () => {
  const saveViewpoint$ = vi.fn(() => of(undefined));
  const getViewpoint$ = vi.fn(() => of({ snapshot: { snapshot_data: 'data:image/png;base64,c25hcHNob3Q=' } }));

  afterEach(() => vi.restoreAllMocks());

  beforeEach(() => {
    vi.spyOn(BcfWpAttributeGroupComponent.prototype, 'ngAfterViewInit').mockImplementation(() => {});
    saveViewpoint$.mockClear();
    getViewpoint$.mockClear();
    TestBed.configureTestingModule({
      imports: [NgxGalleryModule, OpenprojectHalModule],
      declarations: [BcfWpAttributeGroupComponent, BcfNewWpAttributeGroupComponent, OpIconComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: UrlParamsService, useValue: { get: () => null } },
        { provide: BcfAuthorizationService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: WorkPackageCreateService, useValue: {} },
        { provide: ToastService, useValue: { addSuccess: () => {} } },
        { provide: ChangeDetectorRef, useValue: { detectChanges: () => {} } },
        { provide: ViewerBridgeService, useValue: { viewerVisible$: new BehaviorSubject(true), getViewpoint$ } },
        { provide: ViewpointsService, useValue: { saveViewpoint$ } },
      ],
    });
    TestBed.overrideComponent(BcfWpAttributeGroupComponent, { set: { providers: [{ provide: ViewpointsService, useValue: { saveViewpoint$ } }] } });
  });

  it('saves the current persisted work package from the shared template', () => {
    const fixture = TestBed.createComponent(BcfWpAttributeGroupComponent);
    const component = fixture.componentInstance;
    const workPackage = TestBed.inject(HalResourceService).createHalResource<WorkPackageResource>({ _type: 'WorkPackage', id: '42', _links: { self: { href: '/api/v3/work_packages/42' } } });
    component.workPackage = workPackage;
    component.createAllowed = true;
    component.viewAllowed = true;
    fixture.detectChanges();
    fixture.nativeElement.querySelector('button').click();
    expect(saveViewpoint$).toHaveBeenCalledWith(workPackage);
  });

  it('retains a new work package snapshot in the gallery without persisting it', () => {
    const component = TestBed.runInInjectionContext(() => new BcfNewWpAttributeGroupComponent());
    component.saveViewpoint();
    expect(getViewpoint$).toHaveBeenCalledOnce();
    expect(saveViewpoint$).not.toHaveBeenCalled();
    expect(component.galleryViewpoints).toHaveLength(1);
    expect(component.galleryImages[0].small).toBe('data:image/png;base64,c25hcHNob3Q=');
    component.ngOnDestroy();
  });
});
