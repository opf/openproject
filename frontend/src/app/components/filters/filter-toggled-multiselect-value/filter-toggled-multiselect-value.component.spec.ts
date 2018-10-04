//-- copyright
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
//++

import {async, fakeAsync, TestBed} from '@angular/core/testing';
import {ComponentFixture} from '@angular/core/testing/src/component_fixture';
import {FilterToggledMultiselectValueComponent} from './filter-toggled-multiselect-value.component';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {FormsModule} from '@angular/forms';
import {OpIcon} from 'core-app/modules/common/icon/op-icon';
import {DebugElement} from '@angular/core';
import {By} from '@angular/platform-browser';
import {RootDmService} from 'core-app/modules/hal/dm-services/root-dm.service';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {HalResourceSortingService} from "core-app/modules/hal/services/hal-resource-sorting.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

describe('FilterToggledMultiselectValueComponent', () => {
  const I18nStub = {
    t: () => 'PLACEHOLDER'
  };

  let app:FilterToggledMultiselectValueComponent;
  let fixture:ComponentFixture<FilterToggledMultiselectValueComponent>
  let element:HTMLElement;
  let debugElement:DebugElement;

  const allowedValues:any = [
    {
      _type: 'Foo',
      name: 'New York',
      $href: 'api/new_york'
    },
    {
      _type: 'Foo',
      name: 'California',
      $href: 'api/california'
    }
  ];

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        FormsModule,
      ],
      declarations: [
        OpIcon,
        FilterToggledMultiselectValueComponent
      ],
      providers: [
        { provide: I18nService, useValue: I18nStub },
        { provide: PathHelperService, useValue: {} },
        { provide: RootDmService, useValue: {} },
        { provide: HalResourceService, useValue: {} },
        HalResourceSortingService
      ]
    })
      .compileComponents()
      .then(() => {
        fixture = TestBed.createComponent(FilterToggledMultiselectValueComponent);
        app = fixture.debugElement.componentInstance;
        debugElement = fixture.debugElement;
        element = debugElement.nativeElement;
      });
  }));

  describe('with values', function () {
    beforeEach(function () {
      app.filter = {
        name: "BO' SELECTA",
        values: allowedValues,
        currentSchema: {
          values: {
            allowedValues: allowedValues
          }
        },
        $embedded: {} as any,
        $links: {} as any
      } as any;
      fixture.detectChanges();
    });

    describe('app.hasMultipleSelectedOptions()', function () {
      it('is true', () => {
        expect(app.isValueMulti()).toBeTruthy();
      });
    });

    describe('app.value', function () {
      it('is no array', function () {
        expect(Array.isArray(app.value)).toBeTruthy();
      });

      it('is the filter value', function () {
        let value = app.value as HalResource[];

        expect(value.length).toEqual(2);
        expect(value[0]).toEqual(allowedValues[0]);
        expect(value[1]).toEqual(allowedValues[1]);
      });
    });

    describe('element', function () {
      it('should render a div', function () {
        expect(element.tagName).toEqual('DIV');
      });

      it('should render only one select', function () {
        expect(element.querySelectorAll('select').length).toEqual(1);
      });

      it('should render two OPTIONs SELECT', function () {
        var select = element.querySelector('select')!;
        var options = select.querySelectorAll('option');

        expect(options.length).toEqual(2);

        expect(options[0].textContent).toEqual(allowedValues[0].name);
        expect(options[1].textContent).toEqual(allowedValues[1].name);
      });

      it('should render a link that toggles multi-select', fakeAsync(function () {
        expect(app.isMultiselect).toBeTruthy();
        var a = debugElement.query(By.css('.filter-toggled-multiselect--toggler'));

        expect(element.querySelectorAll('select').length).toEqual(1);
        expect(element.querySelectorAll('select[multiple]').length).toEqual(1);

        a.triggerEventHandler('click', null);
        fixture.detectChanges();

        expect(app.isMultiselect).toBeFalsy();

        expect(element.querySelectorAll('select').length).toEqual(1);
        expect(element.querySelectorAll('select[multiple]').length).toEqual(0);
      }));
    });
  });

  describe('w/o values and options', function () {
    beforeEach(function () {
      app.filter = {
        name: "BO' SELECTA",
        values: [],
        currentSchema: {
          values: {
            allowedValues: []
          }
        }
      } as any;

      fixture.detectChanges();
    });

    describe('app.hasMultipleSelectedOptions()', function () {
      it('is false', () => {
        expect(app.isValueMulti()).toBeFalsy();
      });
    });

    describe('app.value', function () {
      it('is no array', function () {
        expect(Array.isArray(app.value)).toBeFalsy();
      });

      it('is null', function () {
        expect(app.value).toBeNull();
      });
    });
  });

  describe('w/o value', function () {
    beforeEach(function () {
      app.filter = {
        name: "BO' SELECTA",
        values: [],
        currentSchema: {
          values: {
            allowedValues: allowedValues
          }
        }
      } as any;

      fixture.detectChanges();
    });

    describe('app.hasMultipleSelectedOptions()', function () {
      it('is false', () => {
        expect(app.isValueMulti()).toBeFalsy();
      });
    });

    describe('app.value', function () {
      it('is no array', function () {
        expect(Array.isArray(app.value)).toBeFalsy();
      });

      it('is null', function () {
        expect(app.value).toBeNull();
      });
    });

    describe('element', function () {
      it('should render two OPTIONs SELECT + Placeholder', function () {
        var select = element.querySelector('select')!;
        var options = select.querySelectorAll('option');

        expect(options.length).toEqual(3);
        expect(options[0].textContent).toEqual('PLACEHOLDER');

        expect(options[1].textContent).toEqual(allowedValues[0].name);
        expect(options[2].textContent).toEqual(allowedValues[1].name);
      });
    });
  });
});

