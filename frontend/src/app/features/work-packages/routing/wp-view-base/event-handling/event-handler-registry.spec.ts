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

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent } from '@testing-library/dom';
import { delegate } from '@knowledgecode/delegate';
import { WorkPackageViewHandlerRegistry } from './event-handler-registry';

describe('WorkPackageViewHandlerRegistry', () => {
  it('removes only its own delegated callback', () => {
    const element = document.createElement('div');
    const button = document.createElement('button');
    button.className = 'trigger';
    element.append(button);
    const own = vi.fn();
    const unrelated = vi.fn();
    class Registry extends WorkPackageViewHandlerRegistry<HTMLElement> {
      protected eventHandlers = [() => ({
        EVENT: 'click' as const,
        SELECTOR: '.trigger',
        eventScope: (view:HTMLElement) => view,
        handleEvent: own,
      })];
    }
    delegate(element).on('click', '.trigger', unrelated);
    const attachment = new Registry(TestBed.inject(Injector)).attachTo(element);
    fireEvent.click(button);
    expect(own).toHaveBeenCalledExactlyOnceWith(element, expect.any(MouseEvent));
    own.mockClear();
    unrelated.mockClear();
    attachment.destroy();
    attachment.destroy();
    fireEvent.click(button);
    expect(own).not.toHaveBeenCalled();
    expect(unrelated).toHaveBeenCalledTimes(1);
    delegate(element).off('click', '.trigger', unrelated);
  });

  it('rolls back registered listeners if a later factory throws', () => {
    const element = document.createElement('div');
    element.innerHTML = '<button class="trigger"></button>';
    const callback = vi.fn();
    const error = new Error('handler construction');
    class Registry extends WorkPackageViewHandlerRegistry<HTMLElement> {
      protected eventHandlers = [
        () => ({
          EVENT: ['click', 'contextmenu'] as ('click'|'contextmenu')[],
          SELECTOR: '.trigger',
          eventScope: (view:HTMLElement) => view,
          handleEvent: callback,
        }),
        () => { throw error; },
      ];
    }
    expect(() => new Registry(TestBed.inject(Injector)).attachTo(element)).toThrow(error);
    fireEvent.click(element.firstElementChild!);
    fireEvent.contextMenu(element.firstElementChild!);
    expect(callback).not.toHaveBeenCalled();
  });
});
