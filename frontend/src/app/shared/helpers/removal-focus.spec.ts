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

import { ApplicationRef, EnvironmentInjector, createEnvironmentInjector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent } from '@testing-library/dom';
import { RemovalFocus, RemovalFocusOptions } from 'core-app/shared/helpers/removal-focus';

describe('RemovalFocus', () => {
  let container:HTMLElement;
  let add:HTMLButtonElement;
  let owner:EnvironmentInjector;

  const item = (name:string) => {
    const element = document.createElement('section');
    const menu = document.createElement('button');
    menu.textContent = `${name} menu`;
    element.appendChild(menu);
    container.insertBefore(element, add);
    return { element, menu };
  };

  const items = () => Array.from(container.querySelectorAll('section'));

  const track = (removed:HTMLElement, options:Partial<RemovalFocusOptions<HTMLElement>> = {}) => new RemovalFocus({
    removed,
    removedElement: removed,
    items,
    control: (element) => element.querySelector('button'),
    fallback: () => [add],
    injector: owner,
    ...options,
  });

  const removeFocused = (removed:{ element:HTMLElement, menu:HTMLElement }) => {
    removed.menu.focus();
    const focus = track(removed.element);
    removed.element.remove();
    return focus;
  };

  beforeEach(() => {
    container = document.createElement('div');
    add = document.createElement('button');
    add.textContent = 'Add';
    container.appendChild(add);
    document.body.appendChild(container);
    owner = createEnvironmentInjector([], TestBed.inject(EnvironmentInjector));
  });

  afterEach(() => {
    if (!owner.destroyed) {
      owner.destroy();
    }
    container.remove();
  });

  it('focuses the next item after the removed one', () => {
    const first = item('First');
    const second = item('Second');
    item('Third');

    removeFocused(first).focusSuccessor();

    expect(second.menu).toHaveFocus();
  });

  it('focuses the previous item after removing the last one', () => {
    item('First');
    const second = item('Second');
    const third = item('Third');

    removeFocused(third).focusSuccessor();

    expect(second.menu).toHaveFocus();
  });

  it('skips a neighbor whose control is not rendered', () => {
    const first = item('First');
    const second = item('Second');
    const third = item('Third');
    third.menu.hidden = true;

    removeFocused(second).focusSuccessor();

    expect(first.menu).toHaveFocus();
  });

  it('focuses the next surviving item when an earlier removal completes first', () => {
    const first = item('First');
    const second = item('Second');
    const third = item('Third');
    item('Fourth');
    second.menu.focus();
    const focus = track(second.element);

    first.element.remove();
    second.element.remove();
    focus.focusSuccessor();

    expect(third.menu).toHaveFocus();
  });

  it('skips a following neighbor without a control for a later one', () => {
    const first = item('First');
    const second = item('Second');
    const third = item('Third');
    second.menu.remove();

    removeFocused(first).focusSuccessor();

    expect(third.menu).toHaveFocus();
  });

  it('focuses the first rendered fallback when no item is left', () => {
    const only = item('Only');
    const hidden = document.createElement('button');
    hidden.hidden = true;

    only.menu.focus();
    const focus = track(only.element, { fallback: () => [hidden, add] });
    only.element.remove();
    focus.focusSuccessor();

    expect(add).toHaveFocus();
  });

  it('leaves focus on the page when nothing is rendered', () => {
    const only = item('Only');
    add.hidden = true;

    removeFocused(only).focusSuccessor();

    expect(document.body).toHaveFocus();
  });

  it('moves focus that is still inside the removed item', () => {
    const first = item('First');
    const second = item('Second');
    first.menu.focus();
    let rendered = [first.element, second.element];
    const focus = track(first.element, { items: () => rendered });

    rendered = [second.element];
    focus.focusSuccessor();

    expect(second.menu).toHaveFocus();
  });

  it('leaves focus alone when another control holds it', () => {
    const first = item('First');
    item('Second');
    const focus = removeFocused(first);

    add.focus();
    focus.focusSuccessor();

    expect(add).toHaveFocus();
  });

  it('does nothing after a pointer press', () => {
    const first = item('First');
    item('Second');
    const focus = removeFocused(first);

    fireEvent.pointerDown(document.body);
    focus.focusSuccessor();

    expect(document.body).toHaveFocus();
  });

  it('does nothing after a key press', () => {
    const first = item('First');
    item('Second');
    const focus = removeFocused(first);

    fireEvent.keyDown(document.body, { key: 'Tab' });
    focus.focusSuccessor();

    expect(document.body).toHaveFocus();
  });

  it('does nothing once cancelled', () => {
    const first = item('First');
    item('Second');
    const focus = removeFocused(first);

    focus.cancel();
    focus.focusSuccessor();

    expect(document.body).toHaveFocus();
  });

  it('does nothing once its owner is destroyed', () => {
    const first = item('First');
    item('Second');
    const focus = removeFocused(first);

    owner.destroy();
    focus.focusSuccessor();

    expect(document.body).toHaveFocus();
  });

  it('moves focus after the next render', async () => {
    const first = item('First');
    const second = item('Second');

    removeFocused(first).focusSuccessorAfterRender();
    expect(second.menu).not.toHaveFocus();
    await TestBed.inject(ApplicationRef).whenStable();

    expect(second.menu).toHaveFocus();
  });

  it('schedules nothing once its owner is destroyed', async () => {
    const first = item('First');
    const second = item('Second');
    const focus = removeFocused(first);

    owner.destroy();

    expect(() => focus.focusSuccessorAfterRender()).not.toThrow();
    await TestBed.inject(ApplicationRef).whenStable();

    expect(second.menu).not.toHaveFocus();
  });

  it('moves focus only once', () => {
    const first = item('First');
    const second = item('Second');
    const third = item('Third');
    const focus = removeFocused(first);

    focus.focusSuccessor();
    second.element.remove();
    focus.focusSuccessor();

    expect(document.body).toHaveFocus();
    expect(third.menu).not.toHaveFocus();
  });
});
