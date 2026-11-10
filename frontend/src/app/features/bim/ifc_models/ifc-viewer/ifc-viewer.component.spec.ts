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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { page, userEvent } from 'vitest/browser';
import { BehaviorSubject, NEVER } from 'rxjs';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { IFCViewerService } from 'core-app/features/bim/ifc_models/ifc-viewer/ifc-viewer.service';
import { IFCViewerComponent } from './ifc-viewer.component';

describe('IFCViewerComponent keyboard warning', () => {
  let fixture:ComponentFixture<IFCViewerComponent>;
  let setKeyboardEnabled:ReturnType<typeof vi.fn>;

  const warning = () => screen.queryByRole('button', { name: 'js.ifc_models.keyboard_input_disabled' });
  const canvas = () => document.querySelector<HTMLCanvasElement>('.op-ifc-viewer--model-canvas')!;

  beforeEach(async () => {
    await page.viewport(1280, 800);
    setKeyboardEnabled = vi.fn();

    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [IFCViewerComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: IfcModelsDataService, useValue: { models: [{}], projects: [], allowed: () => false } },
          { provide: CurrentUserService, useValue: { hasCapabilities$: () => NEVER } },
          { provide: CurrentProjectService, useValue: { id: '1' } },
          {
            provide: IFCViewerService,
            useValue: {
              inspectorVisible$: new BehaviorSubject(false),
              viewerVisible$: NEVER,
              setKeyboardEnabled,
              destroy: vi.fn(),
            },
          },
        ],
        schemas: [NO_ERRORS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(IFCViewerComponent);
    fixture.detectChanges();
    await fixture.whenStable();
  });

  afterEach(() => {
    fixture.destroy();
  });

  it('is a button named by its tooltip', () => {
    const button = warning()!;

    expect(button).toHaveAttribute('type', 'button');
    expect(button.nextElementSibling?.tagName).toBe('TOOL-TIP');
  });

  it('enables keyboard navigation from a pointer click', async () => {
    const focus = vi.spyOn(canvas(), 'focus');
    const button = warning()!;

    fireEvent.mouseDown(button);
    fireEvent.click(button);

    await waitFor(() => expect(warning()).not.toBeInTheDocument());

    expect(setKeyboardEnabled).toHaveBeenCalledExactlyOnceWith(true);
    expect(focus).toHaveBeenCalledOnce();
    expect(canvas()).toHaveFocus();
  });

  it('enables keyboard navigation with Enter', async () => {
    const focus = vi.spyOn(canvas(), 'focus');
    warning()!.focus();

    await userEvent.keyboard('{Enter}');

    await waitFor(() => expect(warning()).not.toBeInTheDocument());

    expect(setKeyboardEnabled).toHaveBeenCalledExactlyOnceWith(true);
    expect(focus).toHaveBeenCalledOnce();
    expect(canvas()).toHaveFocus();
  });

  it('enables keyboard navigation with Space', async () => {
    const focus = vi.spyOn(canvas(), 'focus');
    warning()!.focus();

    await userEvent.keyboard(' ');

    await waitFor(() => expect(warning()).not.toBeInTheDocument());

    expect(setKeyboardEnabled).toHaveBeenCalledExactlyOnceWith(true);
    expect(focus).toHaveBeenCalledOnce();
    expect(canvas()).toHaveFocus();
  });
});
