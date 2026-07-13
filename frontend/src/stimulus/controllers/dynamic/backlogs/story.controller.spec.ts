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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Application } from '@hotwired/stimulus';

import type StoryControllerType from './story.controller';

interface StoryNavigation {
  openSplitPane(this:void):void;
  openFullPane(this:void):void;
}

describe('Backlogs story controller', () => {
  const nextFrame = () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));

  let application:Application;
  let fixture:HTMLElement;
  let StoryController:typeof StoryControllerType;
  let navigation:StoryNavigation;

  beforeAll(async () => {
    ({ default: StoryController } = await import('./story.controller'));
  });

  beforeEach(() => {
    // Stub the navigation so activating a card neither hits Turbo nor leaves
    // the test page; the spies double as activation assertions.
    navigation = StoryController.prototype as unknown as StoryNavigation;
    vi.spyOn(navigation, 'openSplitPane').mockReturnValue(undefined);
    vi.spyOn(navigation, 'openFullPane').mockReturnValue(undefined);

    fixture = document.createElement('div');
    document.body.appendChild(fixture);

    application = Application.start();
    application.register('backlogs--story', StoryController);
  });

  afterEach(() => {
    application.stop();
    fixture.remove();
    vi.restoreAllMocks();
  });

  function renderStory() {
    fixture.innerHTML = `
      <article
        data-controller="backlogs--story"
        data-backlogs--story-id-value="42"
        data-backlogs--story-display-id-value="SP-42"
        data-backlogs--story-split-url-value="/projects/demo/backlogs/details/SP-42"
        data-backlogs--story-full-url-value="/work_packages/42"
        data-backlogs--story-selected-class="Box-row--blue"
        tabindex="0"
      >
        Story
      </article>
    `;

    return fixture.querySelector<HTMLElement>('[data-controller="backlogs--story"]')!;
  }

  function keydown(target:HTMLElement, key:string, init:KeyboardEventInit = {}) {
    const event = new KeyboardEvent('keydown', {
      key, bubbles: true, cancelable: true, ...init,
    });
    target.dispatchEvent(event);
    return event;
  }

  it('prevents Space from scrolling the page without activating the card', async () => {
    const story = renderStory();

    await nextFrame();
    const event = keydown(story, ' ');

    expect(event.defaultPrevented).toBe(true);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });

  it('opens the split pane when Enter is pressed', async () => {
    const story = renderStory();

    await nextFrame();
    const event = keydown(story, 'Enter');

    expect(event.defaultPrevented).toBe(true);
    expect(navigation.openSplitPane).toHaveBeenCalledTimes(1);
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });

  it('opens the full pane when Shift+Enter is pressed', async () => {
    const story = renderStory();

    await nextFrame();
    const event = keydown(story, 'Enter', { shiftKey: true });

    expect(event.defaultPrevented).toBe(true);
    expect(navigation.openFullPane).toHaveBeenCalledTimes(1);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
  });

  it('ignores Space inside a form field so typing and scrolling stay native', async () => {
    const story = renderStory();
    const input = document.createElement('input');
    story.appendChild(input);

    await nextFrame();
    const event = keydown(input, ' ');

    expect(event.defaultPrevented).toBe(false);
    expect(navigation.openSplitPane).not.toHaveBeenCalled();
    expect(navigation.openFullPane).not.toHaveBeenCalled();
  });
});
