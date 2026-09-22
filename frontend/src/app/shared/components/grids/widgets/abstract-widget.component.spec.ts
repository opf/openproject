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

import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';

@Component({
  template: '<h3 [id]="headingId">Widget title</h3>',
  standalone: true,
})
class TestWidgetComponent extends AbstractWidgetComponent {}

describe('AbstractWidgetComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestWidgetComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
  });

  it('labels the widget group with its heading', () => {
    const fixture = TestBed.createComponent(TestWidgetComponent);

    fixture.detectChanges();

    const host = fixture.nativeElement as HTMLElement;
    const heading = host.querySelector<HTMLHeadingElement>('h3')!;

    expect(host.getAttribute('role')).toEqual('group');
    expect(host.getAttribute('aria-labelledby')).toEqual(heading.id);
    expect(heading.id).toMatch(/^widget-heading-/);
  });

  it('generates a unique heading ID for each widget', () => {
    const firstFixture:ComponentFixture<TestWidgetComponent> = TestBed.createComponent(TestWidgetComponent);
    const secondFixture:ComponentFixture<TestWidgetComponent> = TestBed.createComponent(TestWidgetComponent);

    expect(firstFixture.componentInstance.headingId).not.toEqual(secondFixture.componentInstance.headingId);
  });
});
