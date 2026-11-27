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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { QuestionIconComponent } from '@openproject/octicons-angular';
import { StaticAttributeHelpTextComponent } from './static-attribute-help-text.component';
import { StaticAttributeHelpTextModalComponent } from './static-attribute-help-text.modal';

describe('StaticAttributeHelpTextComponent', () => {
  let fixture:ComponentFixture<StaticAttributeHelpTextComponent>;
  let modalServiceStub:{ show:ReturnType<typeof vi.fn> };

  const button = ():HTMLButtonElement => (fixture.nativeElement as HTMLElement).querySelector('button.spot-link')!;

  beforeEach(async () => {
    modalServiceStub = { show: vi.fn() };

    await TestBed
      .configureTestingModule({
        declarations: [StaticAttributeHelpTextComponent],
        providers: [
          { provide: OpModalService, useValue: modalServiceStub },
          { provide: I18nService, useValue: { t: () => 'Show help text' } },
        ],
        imports: [QuestionIconComponent, OpTooltipDirective],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(StaticAttributeHelpTextComponent);
    fixture.componentInstance.title = 'Project folder';
    fixture.componentInstance.content = 'Some help';
    fixture.detectChanges();
  });

  it('renders a native button', () => {
    expect(button()).toBeTruthy();
    expect(button().type).toEqual('button');
  });

  it('names the button by a label tooltip', () => {
    const tooltips = (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('tool-tip');

    expect(tooltips).toHaveLength(1);
    expect(tooltips[0].textContent).toEqual('Show help text');
    expect(tooltips[0].dataset.type).toEqual('label');
    expect(tooltips[0].dataset.direction).toEqual('sw');
    expect(button().getAttribute('aria-labelledby')).toContain(tooltips[0].id);
  });

  it('opens the help text modal on click', () => {
    button().click();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);
    expect(modalServiceStub.show).toHaveBeenCalledWith(
      StaticAttributeHelpTextModalComponent,
      expect.anything(),
      { title: 'Project folder', content: 'Some help' },
    );
  });
});
