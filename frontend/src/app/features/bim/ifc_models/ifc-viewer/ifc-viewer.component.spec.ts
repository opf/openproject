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

import { ElementRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IfcModelsDataService } from '../pages/viewer/ifc-models-data.service';
import { IFCViewerComponent } from './ifc-viewer.component';
import { IFCViewerService } from './ifc-viewer.service';

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
    component.enableKeyBoard();
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
    const event = new MouseEvent('mousedown');
    const stop = vi.spyOn(event, 'stopImmediatePropagation');
    expect(component.enableFromIcon(event)).toBe(false);
    expect(component.keyboardEnabled).toBe(true);
    expect(stop).toHaveBeenCalledOnce();
  });

  it('does not enable or disable keyboard input without models', () => {
    component.modelCount = 0;
    component.keyboardEnabled = false;
    component.enableKeyBoard();
    component.disableKeyboard(document.createElement('button'));
    expect(setKeyboardEnabled).not.toHaveBeenCalled();
  });

  it('destroys its viewer service on teardown', () => {
    component.ngOnDestroy();
    expect(destroy).toHaveBeenCalledOnce();
  });
});
