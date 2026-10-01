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
import { By } from '@angular/platform-browser';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BreadcrumbItem, OpBreadcrumbsComponent } from './op-breadcrumbs.component';

describe('OpBreadcrumbsComponent', () => {
  let fixture:ComponentFixture<OpBreadcrumbsComponent>;
  let component:OpBreadcrumbsComponent;

  const i18nStub = { t: (_key:string) => 'Breadcrumb' };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [
        OpBreadcrumbsComponent,
      ],
      providers: [
        { provide: I18nService, useValue: i18nStub },
      ],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(OpBreadcrumbsComponent);
    component = fixture.componentInstance;
  });

  it('reuses breadcrumb nodes for equivalent items with new object identities', () => {
    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      { href: '/projects/sp/boards/48', text: 'Board 48' },
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      { href: '/projects/sp/boards/48', text: 'Board 48' },
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
    expect(updatedItems[2].nativeElement).toBe(originalItems[2].nativeElement);
  });

  it('keeps unchanged breadcrumb nodes when only the current item changes', () => {
    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Old board name',
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'SP' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'New board name',
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
  });

  it('keeps linked breadcrumb nodes when only the text changes', () => {
    component.items = [
      { href: '/projects/sp', text: 'Old project name' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Board 48',
    ];

    fixture.detectChanges();

    const originalItems = breadcrumbItems();

    component.items = [
      { href: '/projects/sp', text: 'New project name' },
      { href: '/projects/sp/boards', text: 'Boards' },
      'Board 48',
    ];

    fixture.detectChanges();

    const updatedItems = breadcrumbItems();

    expect(updatedItems[0].nativeElement).toBe(originalItems[0].nativeElement);
    expect(updatedItems[1].nativeElement).toBe(originalItems[1].nativeElement);
    expect(updatedItems[2].nativeElement).toBe(originalItems[2].nativeElement);
  });

  it('builds stable tracking keys from breadcrumb values', () => {
    const link:BreadcrumbLink = { href: '/projects/sp', text: 'SP' };

    expect(component.trackBreadcrumbItem(1, link))
      .toEqual('link:/projects/sp:1');
    expect(component.trackBreadcrumbItem(2, 'Board 48'))
      .toEqual('text:Board 48:2');
  });

  function breadcrumbItems() {
    return fixture.debugElement.queryAll(By.css('[data-test-selector="op-breadcrumbs--item"]'));
  }
});

type BreadcrumbLink = Extract<BreadcrumbItem, { href:string; text:string }>;
