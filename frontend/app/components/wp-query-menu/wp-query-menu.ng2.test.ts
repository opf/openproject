//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import {ComponentFixture, TestBed} from '@angular/core/testing';
import {QueryMenuService} from 'core-components/wp-query-menu/wp-query-menu.service';
import {Component} from '@angular/core';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {TransitionService} from '@uirouter/core';
import {$stateToken} from 'core-app/angular4-transition-utils';

@Component({
  template: `
    <li>
      <div id="main-menu-work-packages-wrapper">
        <a id="main-menu-work-packages">Work packages</a>
      </div>
      <ul class="menu-children"></ul>'
    </li>
  `
})
class WpQueryMenuTestComponent { }

describe('wp-query-menu', () => {
  let app:WpQueryMenuTestComponent;
  let fixture:ComponentFixture<WpQueryMenuTestComponent>;
  let element:JQuery;
  let menuContainer:JQuery;

  let queryMenuService:QueryMenuService;
  let transitionCallback:(id:any) => any;

  const $transitionStub = {
    onStart: (criteria:any, callback:(transition:any) => any) => {
      transitionCallback = (id:any) => callback({
        params: (val:string) => { return { queryId: id }; }
      } as any);
    }
  };


  beforeEach((async () => {
    // noinspection JSIgnoredPromiseFromCall
    return TestBed.configureTestingModule({
      declarations: [
        WpQueryMenuTestComponent
      ],
      providers: [
        { provide: $stateToken, useValue: { go: (...args:any[]) => undefined } },
        { provide: WorkPackagesListChecksumService, useValue: { clear: () => undefined } },
        { provide: TransitionService, useValue: $transitionStub },
        { provide: QueryMenuService, useValue: queryMenuService },
      ]
    }).compileComponents()
      .then(() => {
        queryMenuService = TestBed.get(QueryMenuService);
        fixture = TestBed.createComponent(WpQueryMenuTestComponent);
        app = fixture.debugElement.componentInstance;
        element = jQuery(fixture.elementRef.nativeElement);
        menuContainer = element.find('ul.menu-children');
      });
  }));

  describe('#add for a query', function() {
    var menuItem:any, itemLink:any;
    var path = '/work_packages?query_id=1',
        title = 'Query',
        objectId = '1';

    var generateMenuItem = function() {
      queryMenuService.add(title, path, objectId);
      fixture.detectChanges();

      menuItem = menuContainer.children('li');
      itemLink = menuItem.children('a');
    };

    beforeEach(() => {
      generateMenuItem();
    });

    it ('adds a query menu item', function() {
      expect(menuItem).to.have.length(1);
    });

    it('assigns the item type as class', function() {
      expect(itemLink.hasClass('query-menu-item')).to.be.true;
    });

    describe('when the query id matches the query id of the state params', function() {
      beforeEach(inject(function() {
        transitionCallback(objectId);
        fixture.detectChanges();
      }));

      it('marks the new item as selected', function() {
        expect(itemLink.hasClass('selected'), 'is selected').to.be.true;
      });

      it('toggles the selected state on state change', function() {
        transitionCallback(null);
        fixture.detectChanges();
        expect(itemLink.hasClass('selected'), 'is selected').to.be.false;
      });
    });
  });

  describe('#generateMenuItem for the work package index item', function() {
    var menuItem:any, itemLink:any;
    var path = '/work_packages',
        title = 'Work Packages',
        objectId:any = undefined;

    beforeEach(function() {
      queryMenuService.add(title, path, objectId);
      fixture.detectChanges();

      menuItem = menuContainer.children('li');
      itemLink = menuItem.children('a');
    });

    describe('on a work_package page', function() {

      describe('for a null query_id', function() {
        beforeEach(inject(function() {
          transitionCallback(null);
          fixture.detectChanges();
        }));

        it('marks the item as selected', function() {
          expect(itemLink.hasClass('selected'), 'is not selected').to.be.false;
        });
      });
      describe('for a string query_id', function() {
        beforeEach(inject(function() {
          transitionCallback('1');
          fixture.detectChanges();
        }));

        it('does not mark the item as selected', function() {
          expect(itemLink.hasClass('selected'), 'is not selected').to.be.false;
        });
      });
    });
  });
});
