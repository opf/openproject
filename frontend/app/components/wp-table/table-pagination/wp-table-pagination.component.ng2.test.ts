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

import {TableState} from 'core-components/wp-table/table-state/table-state';

require('core-app/angular4-test-setup');

import {async, inject, TestBed} from '@angular/core/testing';
import {$httpToken, $qToken, halResourceFactoryToken, I18nToken, v3PathToken} from 'core-app/angular4-transition-utils';
import {HalRequestService} from 'core-components/api/api-v3/hal-request/hal-request.service';
import {ConfigurationDmService} from 'core-components/api/api-v3/hal-resource-dms/configuration-dm.service';
import {States} from 'core-components/states.service';
import {PaginationInstance} from 'core-components/table-pagination/pagination-instance';
import {IPaginationOptions, PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';

async function setupMocks(paginationService:PaginationService) {
  sinon.stub(paginationService, 'loadPaginationOptions', async () => {
    const options:IPaginationOptions = {
      perPage: 0,
      perPageOptions: [10, 100, 500, 1000],
      maxVisiblePageOptions: 0,
      optionsTruncationSize: 0
    };
    return Promise.resolve(options);
  });
}

function pageString(element:JQuery) {
  return element.find('.pagination--range').text().trim();
}

describe('wpTablePagination Directive', () => {

  beforeEach(async(() => {

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      declarations: [
        WorkPackageTablePaginationComponent
      ],
      providers: [
        States,
        PaginationService,
        WorkPackageTablePaginationService,
        ConfigurationDmService,
        TableState,
        HalRequestService,
        {provide: I18nToken, useValue: (window as any).I18n},
        {provide: v3PathToken, useValue: {}},
        {provide: $qToken, useValue: {}},
        {provide: $httpToken, useValue: {}},
        {provide: halResourceFactoryToken, useValue: {}},
      ]
    }).compileComponents();
  }));

  describe('page ranges and links', function() {

    it('should display the correct page range',
      inject([PaginationService], (paginationService:PaginationService) => {
        setupMocks(paginationService);
        const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
        const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
        const element = jQuery(fixture.elementRef.nativeElement);

        app.pagination = new PaginationInstance(1, 0, 10);
        app.update();
        fixture.detectChanges();
        expect(pageString(element)).to.equal('');

        app.pagination = new PaginationInstance(1, 11, 10);
        app.update();
        fixture.detectChanges();
        expect(pageString(element)).to.equal('(1 - 10/11)');

      }));

    describe('"next" link', function() {
      it('hidden on the last page',
        inject([PaginationService], (paginationService:PaginationService) => {
          setupMocks(paginationService);
          const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
          const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
          const element = jQuery(fixture.elementRef.nativeElement);

          app.pagination = new PaginationInstance(2, 11, 10);
          app.update();
          fixture.detectChanges();

          const liWithNextLink = element.find('.pagination--next-link').parent('li');
          const attrHidden = liWithNextLink.attr('hidden');
          expect(attrHidden).not.to.be.undefined;
        }));
    });

    it('should display correct number of page number links',
      inject([PaginationService], (paginationService:PaginationService) => {
        setupMocks(paginationService);
        const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
        const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
        const element = jQuery(fixture.elementRef.nativeElement);

        function numberOfPageNumberLinks() {
          return element.find('a[rel="next"]').length;
        }

        app.pagination = new PaginationInstance(1, 1, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).to.eq(1);

        app.pagination = new PaginationInstance(1, 11, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).to.eq(2);

        app.pagination = new PaginationInstance(1, 59, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).to.eq(6);
      }));

  });

});



