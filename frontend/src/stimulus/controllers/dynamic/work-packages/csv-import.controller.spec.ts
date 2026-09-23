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

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type CsvImportControllerType from './csv-import.controller';

const IDENTIFIER = 'work-packages--csv-import';
const STATUS_URL = '/projects/seed/work_packages/import/status?job=abc';
const CLEAR_URL = '/projects/seed/work_packages/import';
const CLEAR_STREAM_URL = '/projects/seed/work_packages/import/status';
const MAX_SIZE = 1024;
const TOO_LARGE = 'This file is larger than the 1 kB this instance accepts.';

const loginPage = () => new Response(
  '<html lang="en"><body>Sign in</body></html>',
  { status: 200, headers: { 'Content-Type': 'text/html' } },
);

describe('Work package CSV import controller', () => {
  let ctx:StimulusTestContext;
  let CsvImportController:typeof CsvImportControllerType;
  let fetchSpy:Mock;

  beforeAll(async () => {
    ({ default: CsvImportController } = await import('./csv-import.controller'));
  });

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] });

    // Turbo is live in here, so the streams below really do replace the region. What the run
    // answers a poll with is the report as it stands, which while it lasts still carries the marker.
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(reportStream(pollMarker())));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    ctx = await setupStimulusTest({ controllers: { [IDENTIFIER]: CsvImportController } });
  });

  afterEach(async () => {
    // Disposed while the fake clock is still installed, so the interval is cleared with the same
    // clearInterval that scheduled it. Then the container is gone before the poll still in flight
    // renders: a turbo stream resolves its target by id against the whole document, so one landing
    // late would otherwise replace the next test's report region and set it polling.
    ctx.dispose();
    await ctx.nextFrame();
    await ctx.nextFrame();

    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  function pollMarker(url = STATUS_URL) {
    return `<span hidden data-${IDENTIFIER}-target="poll" data-url="${url}"></span>`;
  }

  function finishedMarker() {
    return `<span hidden data-${IDENTIFIER}-target="finished"></span>`;
  }

  function reportStream(inner:string) {
    return new Response(
      `<turbo-stream action="replace" target="import_report">
         <template><div id="import_report">${inner}</div></template>
       </turbo-stream>`,
      { status: 200, headers: { 'Content-Type': 'text/vnd.turbo-stream.html' } },
    );
  }

  const form = () => `
    <div id="import_form">
      <input type="file" hidden
             data-${IDENTIFIER}-target="file"
             data-action="change->${IDENTIFIER}#fileChosen">

      <button type="button"
              data-${IDENTIFIER}-target="dropBox"
              data-action="click->${IDENTIFIER}#openFilePicker
                           dragover->${IDENTIFIER}#dragOver
                           dragleave->${IDENTIFIER}#dragLeave
                           drop->${IDENTIFIER}#dropFile">
        <span data-${IDENTIFIER}-target="filename"
              data-empty="Drop a CSV file here or click to select one.">Drop a CSV file here or click to select one.</span>
      </button>

      <p hidden data-${IDENTIFIER}-target="sizeError"></p>

      <input type="checkbox" name="dry_run" checked
             data-${IDENTIFIER}-target="dryRun"
             data-action="change->${IDENTIFIER}#nameTheAction">

      <button type="submit" disabled
              data-${IDENTIFIER}-target="submit"
              data-check-label="Check file"
              data-import-label="Import file">Check file</button>

      <a href="${CLEAR_URL}"
         data-action="${IDENTIFIER}#clear"
         data-stream-url="${CLEAR_STREAM_URL}">Clear</a>
    </div>`;

  async function mount(report = '') {
    await ctx.mount(`
      <div data-controller="${IDENTIFIER}"
           data-${IDENTIFIER}-max-size-value="${MAX_SIZE}"
           data-${IDENTIFIER}-too-large-value="${TOO_LARGE}">
        <div id="import_report">${report}</div>
        ${form()}
      </div>`);
  }

  const reportRegion = () => ctx.container.querySelector('#import_report')!;
  const target = (name:string) => ctx.container.querySelector<HTMLElement>(`[data-${IDENTIFIER}-target="${name}"]`)!;
  const fileInput = () => target('file') as HTMLInputElement;
  const submit = () => target('submit') as HTMLButtonElement;
  const hasTarget = (name:string) => !!ctx.container.querySelector(`[data-${IDENTIFIER}-target="${name}"]`);

  function csv(name = 'sprint-43.csv', size = 10) {
    return new File(['a'.repeat(size)], name, { type: 'text/csv' });
  }

  async function choose(file:File) {
    const transfer = new DataTransfer();
    transfer.items.add(file);
    fileInput().files = transfer.files;
    fileInput().dispatchEvent(new Event('change', { bubbles: true }));
    await ctx.nextFrame();
  }

  describe('watching a run', () => {
    it('polls the address on the marker and renders what comes back', async () => {
      fetchSpy.mockResolvedValue(reportStream('<p id="outcome">142 lines checked</p>'));
      await mount(pollMarker());

      await vi.advanceTimersByTimeAsync(2000);

      expect(fetchSpy).toHaveBeenCalledWith(STATUS_URL, {
        headers: { Accept: 'text/vnd.turbo-stream.html' },
      });
      await waitFor(() => expect(reportRegion().textContent).toContain('142 lines checked'));
    });

    it('does not poll when there is no run to watch', async () => {
      await mount();

      await vi.advanceTimersByTimeAsync(6000);

      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('keeps exactly one poll running however often the report is replaced', async () => {
      await mount(pollMarker());

      await vi.advanceTimersByTimeAsync(2000);
      await waitFor(() => expect(fetchSpy).toHaveBeenCalledTimes(1));
      await vi.advanceTimersByTimeAsync(2000);
      await waitFor(() => expect(fetchSpy).toHaveBeenCalledTimes(2));
      await vi.advanceTimersByTimeAsync(2000);

      expect(fetchSpy).toHaveBeenCalledTimes(3);
    });

    it('stops once the report says the run is over', async () => {
      await mount(pollMarker());
      fetchSpy.mockResolvedValue(reportStream(finishedMarker()));

      await vi.advanceTimersByTimeAsync(2000);
      await waitFor(() => expect(hasTarget('finished')).toBe(true));
      fetchSpy.mockClear();

      await vi.advanceTimersByTimeAsync(6000);

      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('gives up rather than hammering a server that has stopped answering', async () => {
      fetchSpy.mockResolvedValue(new Response('', { status: 500 }));
      await mount(pollMarker());

      await vi.advanceTimersByTimeAsync(20_000);

      expect(fetchSpy).toHaveBeenCalledOnce();
    });

    it('gives up on a page served where a report was asked for', async () => {
      fetchSpy.mockResolvedValue(loginPage());
      await mount(pollMarker());

      await vi.advanceTimersByTimeAsync(20_000);

      expect(fetchSpy).toHaveBeenCalledOnce();
      expect(reportRegion().textContent).not.toContain('Sign in');
    });

    it('keeps watching when a request never arrives, since the network can come back', async () => {
      fetchSpy.mockRejectedValue(new Error('network down'));
      await mount(pollMarker());

      await vi.advanceTimersByTimeAsync(6000);

      expect(fetchSpy).toHaveBeenCalledTimes(3);
      expect(hasTarget('poll')).toBe(true);
    });
  });

  describe('choosing a file', () => {
    it('names the file on the drop box and lets the run be started', async () => {
      await mount();

      await choose(csv());

      expect(target('filename').textContent).toEqual('sprint-43.csv');
      expect(submit().disabled).toBe(false);
    });

    it('refuses a file over the limit rather than uploading it', async () => {
      await mount();

      await choose(csv('huge.csv', MAX_SIZE + 1));

      expect(target('sizeError').textContent).toEqual(TOO_LARGE);
      expect(target('sizeError').hidden).toBe(false);
      expect(submit().disabled).toBe(true);
    });

    it('swaps the button label with the checkbox, so it always names what will happen', async () => {
      await mount();
      const dryRun = target('dryRun') as HTMLInputElement;

      dryRun.checked = false;
      dryRun.dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(submit().textContent).toEqual('Import file');
    });

    it('puts a dropped file on the field the form actually submits', async () => {
      await mount();
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(csv());

      target('dropBox').dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
      await ctx.nextFrame();

      expect(fileInput().files?.[0].name).toEqual('sprint-43.csv');
      expect(target('filename').textContent).toEqual('sprint-43.csv');
      expect(submit().disabled).toBe(false);
    });
  });

  describe('clearing the report', () => {
    const clearLink = () => ctx.container.querySelector<HTMLAnchorElement>('a[data-action]')!;

    async function clear() {
      const event = new MouseEvent('click', { bubbles: true, cancelable: true });
      clearLink().dispatchEvent(event);
      await ctx.nextFrame();
      return event;
    }

    it('resets the report in place, and stops watching the run it put away', async () => {
      const replaceState = vi.spyOn(window.history, 'replaceState');
      fetchSpy.mockResolvedValue(reportStream(''));
      await mount(pollMarker());

      const event = await clear();

      expect(event.defaultPrevented).toBe(true);
      expect(fetchSpy).toHaveBeenCalledWith(CLEAR_STREAM_URL, {
        headers: { Accept: 'text/vnd.turbo-stream.html' },
      });
      await waitFor(() => expect(hasTarget('poll')).toBe(false));
      // Turbo keeps its own history entries, so this is one call among several rather than the only one.
      await waitFor(() => expect(replaceState).toHaveBeenCalledWith({}, '', clearLink().href));

      fetchSpy.mockClear();
      await vi.advanceTimersByTimeAsync(6000);
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('visits the page rather than rendering a login page into the report', async () => {
      fetchSpy.mockResolvedValue(loginPage());
      await mount(pollMarker());
      clearLink().setAttribute('href', '#expired');

      await clear();

      await waitFor(() => expect(window.location.hash).toEqual('#expired'));
      expect(reportRegion().textContent).not.toContain('Sign in');

      window.location.hash = '';
    });

    it('visits the page when the reset request never arrives', async () => {
      fetchSpy.mockRejectedValue(new Error('network down'));
      await mount(pollMarker());
      clearLink().setAttribute('href', '#offline');

      await clear();

      await waitFor(() => expect(window.location.hash).toEqual('#offline'));

      window.location.hash = '';
    });
  });
});
