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
import { CUSTOM_ELEMENTS_SCHEMA, DebugElement } from '@angular/core';
import { AttributeHelpTextComponent } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.component';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { AttributeHelpTextsService } from './attribute-help-text.service';
import { AttributeHelpTextModalService } from './attribute-help-text-modal.service';
import { QuestionIconComponent } from '@openproject/octicons-angular';
import { OpIconComponent } from '../icon/icon.component';

describe('AttributeHelpTextComponent', () => {
  let component:AttributeHelpTextComponent;
  let fixture:ComponentFixture<AttributeHelpTextComponent>;
  let element:DebugElement;

  const serviceStub = {};
  let modalServiceStub:{ show:ReturnType<typeof vi.fn> };
  const i18nStub = { t: (_scope:string | string[], _options?:Record<string, any>) => 'Show help text' };
  const pathHelperStub = {
    attributeHelpTextsShowDialogPath: (id:string|number) => `/attribute_help_texts/${id}/show_dialog`,
  };

  const link = ():HTMLAnchorElement => element.query(By.css('a.op-attribute-help-text')).nativeElement as HTMLAnchorElement;

  const settle = async () => {
    fixture.detectChanges();
    await Promise.resolve();
    await modalServiceStub.show.mock.results.at(-1)!.value;
    await new Promise((resolve) => setTimeout(resolve, 0));
    fixture.detectChanges();
  };

  beforeEach(async () => {
    modalServiceStub = {
      show: vi.fn().mockName('AttributeHelpTextModalService.show'),
    };
    modalServiceStub.show.mockResolvedValue(undefined);

    await TestBed
      .configureTestingModule({
        declarations: [
          AttributeHelpTextComponent,
          OpIconComponent,
        ],
        providers: [
          { provide: AttributeHelpTextsService, useValue: serviceStub },
          { provide: AttributeHelpTextModalService, useValue: modalServiceStub },
          { provide: I18nService, useValue: i18nStub },
          { provide: PathHelperService, useValue: pathHelperStub },
        ],
        imports: [
          QuestionIconComponent,
          OpTooltipDirective,
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AttributeHelpTextComponent);
    component = fixture.debugElement.componentInstance;
    component.helpTextId = 1;
    component.attribute = 'subject';
    component.attributeScope = 'Project';
    element = fixture.debugElement;

    fixture.detectChanges();
  });

  it('renders a Primer link to the help text dialog', () => {
    expect(link().classList).toContain('Link');
    expect(link().classList).toContain('help-text--entry');
    expect(link().getAttribute('href')).toEqual('/attribute_help_texts/1/show_dialog');
    expect(link().id).toMatch(/attribute-help-text-component-\d+/);
    expect(link().dataset.qaHelpTextFor).toEqual('subject');
  });

  it('names the link by a label tooltip', () => {
    const tooltips = element.queryAll(By.css('tool-tip'));

    expect(tooltips).toHaveLength(1);
    const tooltip = tooltips[0].nativeElement as HTMLElement;
    expect(tooltip.textContent).toEqual('Show help text');
    expect(tooltip.getAttribute('for')).toEqual(link().id);
    expect(tooltip.dataset.direction).toEqual('sw');
    expect(tooltip.dataset.type).toEqual('label');
    expect(link().getAttribute('aria-labelledby')).toContain(tooltip.id);
  });

  it('renders an icon', () => {
    const icon = element.query(By.directive(QuestionIconComponent));

    expect(icon.nativeElement.getAttribute('size')).toEqual('xsmall');
  });

  it('opens the dialog on click and is disabled while loading', async () => {
    link().click();
    fixture.detectChanges();

    expect(link().getAttribute('aria-disabled')).toEqual('true');

    await settle();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);
    expect(modalServiceStub.show).toHaveBeenCalledWith('1');
    expect(link().getAttribute('aria-disabled')).toEqual('false');
  });

  it('opens the dialog once on Enter followed by the native click', async () => {
    link().dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    link().click();
    await settle();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);
  });

  it('ignores repeated clicks while loading', async () => {
    link().click();
    fixture.detectChanges();
    link().click();
    await settle();

    expect(modalServiceStub.show).toHaveBeenCalledTimes(1);
  });
});
