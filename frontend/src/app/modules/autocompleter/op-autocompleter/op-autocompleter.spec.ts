import { ComponentFixture, fakeAsync, flush, TestBed, tick, waitForAsync } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { OpAutocompleterComponent } from "./op-autocompleter.component";
import { OpAutocompleterService } from "./services/op-autocompleter.service";
import { DebugElement, NO_ERRORS_SCHEMA } from '@angular/core';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { of } from "rxjs";
import { NgSelectComponent} from '@ng-select/ng-select';
import { NgSelectModule } from "@ng-select/ng-select";
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import { By } from '@angular/platform-browser';

function triggerKeyDownEvent(element:DebugElement, which:number, key = ''):void {
  element.triggerEventHandler('keydown', {
    which: which,
    key: key,
    preventDefault: () => {
    },
  });
}

function getNgSelectElement(fixture:ComponentFixture<any>):DebugElement {
  return fixture.debugElement.query(By.css('ng-select'));
}

describe('autocompleter', () => {
  let fixture:ComponentFixture<OpAutocompleterComponent>;
  let opAutocompleterServiceSpy:jasmine.SpyObj<OpAutocompleterService>;
  const workPackagesStub = [
    {
      id: 1,
      subject: 'Workpackage 1',
      name: 'Workpackage 1',
      author: {
        href: '/api/v3/users/1',
        name: 'Author1',
      },
      description: {
        format: 'markdown',
        raw: 'Description of WP1',
        html: '<p>Description of WP1</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
    {
      id: 2,
      subject: 'Workpackage 2',
      name: 'Workpackage 2',
      author: {
        href: '/api/v3/users/2',
        name: 'Author2',
      },
      description: {
        format: 'markdown',
        raw: 'Description of WP2',
        html: '<p>Description of WP2</p>',
      },
      createdAt: '2021-03-26T10:42:14Z',
      updatedAt: '2021-03-26T10:42:14Z',
      dueDate: '2021-03-26T10:42:14Z',
      startDate: '2021-03-26T10:42:14Z',
    },
  ];

  beforeEach(() => {
    opAutocompleterServiceSpy = jasmine.createSpyObj('OpAutocompleterService', ['loadData']);

    TestBed.configureTestingModule({
      declarations: [
        OpAutocompleterComponent],
      providers: [
        // { provide: OpAutocompleterService, useValue: opAutocompleterServiceSpyFactory }
      ],
      imports: [HttpClientTestingModule, NgSelectModule],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(
        OpAutocompleterComponent,
        { set: { providers: [{ provide: OpAutocompleterService, useValue: opAutocompleterServiceSpy }] } })
      .compileComponents();

    fixture = TestBed.createComponent(OpAutocompleterComponent);

    fixture.componentInstance.resource = 'work_packages' as resource;
    fixture.componentInstance.filters = [];
    fixture.componentInstance.searchKey = 'subjectOrId';
    fixture.componentInstance.appendTo = 'body';
    fixture.componentInstance.multiple = false;
    fixture.componentInstance.closeOnSelect = true;
    fixture.componentInstance.hasDefaultContent = true;
    fixture.componentInstance.virtualScroll = true;
    fixture.componentInstance.classes = 'wp-inline-create--reference-autocompleter';
    fixture.componentInstance.defaulData = true;

    // @ts-ignore
    opAutocompleterServiceSpy.loadData.and.returnValue(of(workPackagesStub));
  });

  it('should load the ng-select correctly', () => {
    fixture.detectChanges();
    fixture.whenStable().then(() => {
      const autocompleter = document.querySelector('.ng-select-container');
      expect(document.contains(autocompleter)).toBeTruthy();
    });
  });

  it('should load WorkPackages', fakeAsync(() => {
    tick();
    fixture.detectChanges();
    fixture.componentInstance.ngAfterViewInit();
    tick(1000);
    fixture.detectChanges();
    var select =  fixture.componentInstance.ngSelectInstance as NgSelectComponent;
    expect(fixture.componentInstance.ngSelectInstance.isOpen).toBeFalse();
    fixture.componentInstance.ngSelectInstance.open();
    fixture.componentInstance.ngSelectInstance.focus();
    expect(fixture.componentInstance.ngSelectInstance.isOpen).toBeTrue();
    select.filter('a');

    fixture.detectChanges();
    tick(1000);
    fixture.detectChanges();
    tick(1000);
    
  expect(opAutocompleterServiceSpy.loadData).toHaveBeenCalledWith('a', 
  fixture.componentInstance.resource, fixture.componentInstance.filters, fixture.componentInstance.searchKey);
  
  expect(fixture.componentInstance.ngSelectInstance.itemsList.items.length).toEqual(2);

  }));
});