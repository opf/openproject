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

require('../../../angular4-test-setup');

import {async, inject, TestBed} from '@angular/core/testing';
import {$httpToken, $qToken, halResourceFactoryToken, I18nToken, v3PathToken} from 'core-app/angular4-transition-utils';
import {HalRequestService} from 'core-components/api/api-v3/hal-request/hal-request.service';
import {ConfigurationDmService} from 'core-components/api/api-v3/hal-resource-dms/configuration-dm.service';
import {States} from 'core-components/states.service';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';


describe('AppComponent', () => {

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [
        WorkPackageTablePaginationComponent
      ],
      providers: [
        States,
        PaginationService,
        WorkPackageTablePaginationService,
        ConfigurationDmService,
        HalRequestService,
        {provide: v3PathToken, useValue: null},
        {provide: $qToken, useValue: null},
        {provide: $httpToken, useValue: null},
        {provide: halResourceFactoryToken, useValue: null},
        {provide: I18nToken, useValue: (window as any).I18n}
      ]
    }).compileComponents();
  }));

  it('dummy', inject([PaginationService], (paginationService:PaginationService) => {
    expect(2).to.eq(2);

    console.log('paginationService', paginationService);

    const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
    const app = fixture.debugElement.componentInstance;
    const element = fixture.elementRef.nativeElement;

    console.log('fixture', fixture);
    console.log('app', app);
    console.log('element', element);
  }));

});



