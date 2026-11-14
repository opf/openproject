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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import DestinationRevealController from './destination-reveal.controller';

const identifier = 'backlogs--destination-reveal';
const movedEvent = 'op-dispatched:backlogs:work-package-moved';
const action = [
  `turbo:before-stream-render@document->${identifier}#onBeforeStreamRender`,
  `turbo:before-fetch-request->${identifier}#onFrameRequest`,
  `turbo:before-fetch-response->${identifier}#onFrameResponse`,
  `turbo:fetch-request-error->${identifier}#onFrameFailed`,
  `turbo:frame-missing->${identifier}#onFrameFailed`,
  `turbo:frame-load->${identifier}#onFrameLoad`,
  `${movedEvent}@document->${identifier}#onWorkPackageMoved`,
].join(' ');

interface MovedDetail {
  work_package_ids?:number[];
  work_package_id?:number;
  destination_changed?:boolean;
  destination?:{ list_type:string; list_id:number|null };
}

describe('Backlogs destination reveal', () => {
  let ctx:StimulusTestContext;
  let frame:HTMLElement;
  let first:HTMLElement;
  let second:HTMLElement;
  let focusHost:HTMLButtonElement;
  let scroll:ReturnType<typeof vi.spyOn>;
  let focus:ReturnType<typeof vi.spyOn>;

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { [identifier]: DestinationRevealController } });
    await ctx.mount(`
      <button id="focus-host">Keep focus</button>
      <turbo-frame id="backlogs_container" data-controller="${identifier}" data-action="${action}">
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="9">
          <li><article data-${identifier}-target="card" data-backlogs--work-package-id-value="42"></article></li>
          <li><article data-${identifier}-target="card" data-backlogs--work-package-id-value="43"></article></li>
        </ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="inbox"></ul>
      </turbo-frame>
    `);
    frame = ctx.container.querySelector<HTMLElement>('turbo-frame')!;
    [first, second] = Array.from(frame.querySelectorAll<HTMLElement>('article'));
    focusHost = ctx.container.querySelector<HTMLButtonElement>('button')!;
    focusHost.focus();
    scroll = vi.spyOn(Element.prototype, 'scrollIntoView').mockImplementation(() => undefined);
    focus = vi.spyOn(HTMLElement.prototype, 'focus');
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  function beginReload() {
    const stream = document.createElement('turbo-stream');
    stream.setAttribute('action', 'turbo_frame_reload');
    stream.setAttribute('target', frame.id);
    document.dispatchEvent(new CustomEvent('turbo:before-stream-render', { detail: { newStream: stream } }));
    requestFrame();
  }

  function requestFrame() {
    frame.dispatchEvent(new CustomEvent('turbo:before-fetch-request', {
      bubbles: true, detail: { fetchOptions: { method: 'GET' }, url: new URL(window.location.href) },
    }));
  }

  function moved(detail:MovedDetail = {}) {
    document.dispatchEvent(new CustomEvent(movedEvent, { detail: {
      work_package_ids: [42, 43], destination_changed: true,
      destination: { list_type: 'sprint', list_id: 9 }, ...detail,
    } }));
  }

  function complete(target = frame) {
    target.dispatchEvent(new Event('turbo:frame-load', { bubbles: true }));
  }

  async function settle() {
    await ctx.nextFrame();
    await ctx.nextFrame();
  }

  it.each(['event-first', 'frame-first'])('reveals only the first ID after normal focus settles: %s', async (order) => {
    beginReload();
    if (order === 'event-first') moved();
    else complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
    if (order === 'event-first') complete();
    else moved();
    expect(scroll).not.toHaveBeenCalled();
    await ctx.nextFrame();
    expect(scroll).not.toHaveBeenCalled();
    await ctx.nextFrame();

    expect(scroll).toHaveBeenCalledExactlyOnceWith({ block: 'nearest', inline: 'nearest' });
    expect(scroll.mock.contexts).toEqual([first]);
    expect(document.activeElement).toBe(focusHost);
    expect(focus).not.toHaveBeenCalled();
    complete();
    await settle();
    expect(scroll).toHaveBeenCalledTimes(1);
  });

  it('uses the member ID and scopes inbox identity with a null list ID', async () => {
    frame.querySelector('[data-sortable-lists--list-type-value="inbox"]')!.append(first.parentElement!);
    beginReload();
    moved({ work_package_ids: undefined, work_package_id: 42, destination: { list_type: 'inbox', list_id: null } });
    complete();
    await settle();
    expect(scroll.mock.contexts).toEqual([first]);
  });

  it('uses the submitted ID order rather than DOM order', async () => {
    beginReload();
    moved({ work_package_ids: [43, 42] });
    complete();
    await settle();
    expect(scroll.mock.contexts).toEqual([second]);
  });

  it.each(['absent', 'wrong-list'])('does not substitute a later member when the first is %s', async (location) => {
    if (location === 'absent') first.remove();
    else frame.querySelector('[data-sortable-lists--list-type-value="inbox"]')!.append(first.parentElement!);
    beginReload();
    moved();
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
    frame.querySelector('ul')!.append(first);
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it.each([
    { list_type: 'sprint', list_id: 10 },
    { list_type: 'backlog_bucket', list_id: 9 },
  ])('does not reveal a matching record in another destination: %j', async (destination) => {
    beginReload();
    moved({ destination });
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('does not associate a stream targeting another owning view', async () => {
    const stream = document.createElement('turbo-stream');
    stream.setAttribute('action', 'turbo_frame_reload');
    stream.setAttribute('target', 'another-backlogs-frame');
    document.dispatchEvent(new CustomEvent('turbo:before-stream-render', { detail: { newStream: stream } }));
    requestFrame();
    moved();
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it.each([
    { destination_changed: false },
    { destination_changed: undefined },
    { work_package_ids: [], work_package_id: undefined },
    { destination: undefined },
  ])('ignores same-list or incomplete event detail: %j', async (detail) => {
    beginReload();
    moved(detail);
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('ignores unrelated frame completion and reveals on its own completion', async () => {
    const child = document.createElement('turbo-frame');
    frame.append(child);
    beginReload();
    moved();
    complete(child);
    await settle();
    expect(scroll).not.toHaveBeenCalled();
    complete();
    await settle();
    expect(scroll.mock.contexts).toEqual([first]);
  });

  it('ignores moved events without an associated owning-frame reload', async () => {
    complete();
    moved();
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('does not arm a reveal for a failed move or an unrelated reload', async () => {
    beginReload();
    complete();
    await settle();
    requestFrame();
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it.each(['turbo:fetch-request-error', 'turbo:frame-missing', 'turbo:before-fetch-response'])('expires pending state on %s', async (eventName) => {
    beginReload();
    moved();
    frame.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail: { fetchResponse: { succeeded: false } } }));
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('expires pending state when an unrelated request supersedes its move frame', async () => {
    beginReload();
    moved();
    requestFrame();
    complete();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('supersedes a scheduled reveal with the next move/frame lifetime', async () => {
    beginReload();
    moved();
    complete();
    beginReload();
    moved({ work_package_ids: [43] });
    await settle();
    expect(scroll).not.toHaveBeenCalled();
    complete();
    await settle();
    expect(scroll.mock.contexts).toEqual([second]);
  });

  it('cancels an already scheduled reveal on a newer same-list event', async () => {
    beginReload();
    moved();
    complete();
    moved({ destination_changed: false });
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });

  it('cancels pending animation frames on disconnect', async () => {
    beginReload();
    moved();
    complete();
    frame.remove();
    await settle();
    expect(scroll).not.toHaveBeenCalled();
  });
});
