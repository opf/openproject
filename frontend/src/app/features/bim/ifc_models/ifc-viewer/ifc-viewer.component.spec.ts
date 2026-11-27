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

import { NO_ERRORS_SCHEMA, ElementRef } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { page, userEvent } from 'vitest/browser';
import { BehaviorSubject, NEVER, of } from 'rxjs';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { IFCViewerService } from 'core-app/features/bim/ifc_models/ifc-viewer/ifc-viewer.service';
import { IFCViewerComponent } from './ifc-viewer.component';
import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';

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

describe('IFCViewerComponent keys for page shortcuts', () => {
  let fixture:ComponentFixture<IFCViewerComponent>;
  let shortcutKeys:string[];
  const recordShortcutKey = (event:KeyboardEvent) => {
    if (!event.defaultPrevented) {
      shortcutKeys.push(event.key);
    }
  };
  const releaseHeldKeys = vi.fn();

  const canvas = () => document.querySelector<HTMLCanvasElement>('.op-ifc-viewer--model-canvas')!;
  const toolbarButton = () => document.querySelector<HTMLButtonElement>('#xeokit-replace-reset')!;

  beforeEach(async () => {
    shortcutKeys = [];
    releaseHeldKeys.mockClear();
    document.addEventListener('keydown', recordShortcutKey);

    await TestBed
      .configureTestingModule({
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
              viewerVisible$: new BehaviorSubject(false),
              setKeyboardEnabled: vi.fn(),
              handlesKey: (event:KeyboardEvent) => event.key === 's',
              releaseHeldKeys,
              destroy: vi.fn(),
            } satisfies Partial<IFCViewerService>,
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
    document.removeEventListener('keydown', recordShortcutKey);
    fixture.destroy();
  });

  const enableKeyboard = () => {
    fireEvent.mouseDown(canvas());
    canvas().focus();
  };

  it('claims a camera key on the canvas from the page shortcuts', async () => {
    enableKeyboard();

    await userEvent.keyboard('s');

    expect(shortcutKeys).toEqual([]);
  });

  it.each(['Control', 'Meta', 'Alt'])('leaves a camera key with %s on the canvas to the browser', async (modifier) => {
    enableKeyboard();

    await userEvent.keyboard(`{${modifier}>}s{/${modifier}}`);

    expect(shortcutKeys).toContain('s');
  });

  it('leaves other keys on the canvas to the page shortcuts', async () => {
    enableKeyboard();

    await userEvent.keyboard('j');

    expect(shortcutKeys).toEqual(['j']);
  });

  it('releases the viewer\'s held keys when a page shortcut moves focus off the canvas', async () => {
    enableKeyboard();
    const moveFocus = (event:KeyboardEvent) => {
      if (event.key === 'j') {
        toolbarButton().focus();
      }
    };
    document.addEventListener('keydown', moveFocus);

    await userEvent.keyboard('j');
    document.removeEventListener('keydown', moveFocus);

    expect(toolbarButton()).toHaveFocus();
    expect(releaseHeldKeys).toHaveBeenCalledExactlyOnceWith(canvas());
  });

  it('keeps the viewer\'s held keys when focus leaves another viewer control', () => {
    enableKeyboard();
    fireEvent.focusOut(toolbarButton());

    expect(releaseHeldKeys).not.toHaveBeenCalled();
  });

  it('leaves a camera key on a toolbar button to the page shortcuts', async () => {
    enableKeyboard();
    toolbarButton().focus();

    await userEvent.keyboard('s');

    expect(shortcutKeys).toEqual(['s']);
  });

  it('leaves a camera key on the canvas to the page shortcuts while keyboard navigation is off', async () => {
    canvas().focus();

    await userEvent.keyboard('s');

    expect(shortcutKeys).toEqual(['s']);
  });
});

describe('IFCViewerComponent viewer creation', () => {
  let fixture:ComponentFixture<IFCViewerComponent>;
  let treePanel:HTMLElement;
  const setKeyboardEnabled = vi.fn();

  beforeEach(async () => {
    setKeyboardEnabled.mockClear();
    treePanel = document.createElement('div');
    treePanel.classList.add('op-ifc-viewer--tree-panel');
    document.body.append(treePanel);

    await TestBed
      .configureTestingModule({
        declarations: [IFCViewerComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: IfcModelsDataService, useValue: { models: [{}], projects: [], allowed: () => false } },
          { provide: CurrentUserService, useValue: { hasCapabilities$: () => of(false) } },
          { provide: CurrentProjectService, useValue: { id: '1' } },
          {
            provide: IFCViewerService,
            useValue: {
              inspectorVisible$: new BehaviorSubject(false),
              viewerVisible$: new BehaviorSubject(false),
              newViewer: () => Promise.resolve(),
              setKeyboardEnabled,
              destroy: vi.fn(),
            } satisfies Partial<IFCViewerService>,
          },
        ],
        schemas: [NO_ERRORS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(IFCViewerComponent);
  });

  afterEach(() => {
    fixture.destroy();
    treePanel.remove();
  });

  it('starts the new viewer with keyboard navigation off', async () => {
    fixture.detectChanges();
    await fixture.whenStable();

    await waitFor(() => expect(setKeyboardEnabled).toHaveBeenCalledWith(false));
  });
});

describe('IFCViewerComponent keyboard targeting', () => {
  let component:IFCViewerComponent;
  const setKeyboardEnabled = vi.fn();
  const destroy = vi.fn();

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [
      { provide: IfcModelsDataService, useValue: { models: [{}], allowed: () => true } },
      { provide: I18nService, useValue: { t: (key:string) => key } },
      { provide: CurrentUserService, useValue: {} },
      { provide: CurrentProjectService, useValue: {} },
      { provide: IFCViewerService, useValue: { inspectorVisible$: new BehaviorSubject(false), setKeyboardEnabled, destroy } },
    ] });
    setKeyboardEnabled.mockClear();
    destroy.mockClear();
    component = TestBed.runInInjectionContext(() => new IFCViewerComponent());
    component.outerContainer = new ElementRef(document.createElement('div'));
    component.modelCanvas = new ElementRef(document.createElement('canvas'));
    component.outerContainer.nativeElement.append(component.modelCanvas.nativeElement);
    component.enableKeyboard();
    setKeyboardEnabled.mockClear();
  });

  it('keeps keyboard input enabled for a canvas target inside the viewer', () => {
    component.disableKeyboard(component.modelCanvas.nativeElement);
    expect(component.keyboardEnabled).toBe(true);
    expect(setKeyboardEnabled).not.toHaveBeenCalled();
  });

  it('disables keyboard input for an element outside the viewer', () => {
    component.disableKeyboard(document.createElement('button'));
    expect(component.keyboardEnabled).toBe(false);
    expect(setKeyboardEnabled).toHaveBeenCalledWith(false);
  });

  it.each([null, new EventTarget(), document.createTextNode('text')])('ignores a non-element event target %s', (target) => {
    component.disableKeyboard(target);
    expect(component.keyboardEnabled).toBe(true);
    expect(setKeyboardEnabled).not.toHaveBeenCalled();
  });

  it('keeps the icon activation from reaching the window handler', () => {
    component.keyboardEnabled = false;
    const event = new MouseEvent('mousedown');
    const stop = vi.spyOn(event, 'stopImmediatePropagation');
    expect(component.enableFromIcon(event)).toBe(false);
    expect(component.keyboardEnabled).toBe(true);
    expect(stop).toHaveBeenCalledOnce();
  });

  it('does not enable or disable keyboard input without models', () => {
    component.modelCount = 0;
    component.keyboardEnabled = false;
    component.enableKeyboard();
    component.disableKeyboard(document.createElement('button'));
    expect(setKeyboardEnabled).not.toHaveBeenCalled();
  });

  it('destroys its viewer service on teardown', () => {
    component.ngOnDestroy();
    expect(destroy).toHaveBeenCalledOnce();
  });
});
