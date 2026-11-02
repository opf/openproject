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

import { waitFor } from '@testing-library/dom';
import { vi, type MockInstance } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import GenerationStatusController from './generation-status.controller';

describe('Test management generation status controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:MockInstance<typeof window.fetch>;
  let csrfMeta:HTMLMetaElement;
  let frameReload:ReturnType<typeof vi.fn<() => void>>;

  beforeEach(async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'setInterval', 'clearInterval'] });

    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'csrf-token-value';
    document.head.append(csrfMeta);

    frameReload = vi.fn<() => void>();
    const frame = document.createElement('turbo-frame');
    frame.id = 'tm-draft-results';
    (frame as unknown as { reload:() => void }).reload = frameReload;
    const heading = document.createElement('h2');
    heading.id = 'tm-draft-results-heading';
    heading.tabIndex = -1;
    frame.append(heading);
    document.body.append(frame);

    fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({
        state: 'running',
        step: 'writing_drafts',
        progress: { done: 1, total: 3 },
        message: 'Writing drafts… 1 of 3',
        started_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        error: null,
      }), { status: 200, headers: { 'Content-Type': 'application/json' } }),
    );

    ctx = await setupStimulusTest({
      controllers: { 'test-management--generation-status': GenerationStatusController },
    });
  });

  afterEach(() => {
    ctx?.dispose();
    csrfMeta.remove();
    document.getElementById('tm-draft-results')?.remove();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  async function mountPending() {
    await ctx.mount(`
      <div data-controller="test-management--generation-status"
           data-test-management--generation-status-url-value="/status"
           data-test-management--generation-status-cancel-url-value="/cancel"
           data-test-management--generation-status-retry-url-value="/retry"
           data-test-management--generation-status-interval-value="2500"
           data-test-management--generation-status-timeout-value="300000"
           data-test-management--generation-status-frame-id-value="tm-draft-results"
           data-test-management--generation-status-frame-url-value="/generations/1"
           data-test-management--generation-status-progress-message-value="Writing drafts… %{done} of %{total}"
           data-test-management--generation-status-succeeded-message-value="%{count} draft test cases ready"
           data-test-management--generation-status-failed-message-value="Generation failed: %{error}"
           data-test-management--generation-status-cancelled-message-value="Cancelled"
           data-test-management--generation-status-timeout-message-value="Still working — check again"
           data-test-management--generation-status-reconnect-message-value="Reconnecting…">
        <div data-test-management--generation-status-target="banner" aria-live="polite">
          <span data-test-management--generation-status-target="message">Writing drafts…</span>
          <span data-test-management--generation-status-target="elapsed"></span>
          <span data-test-management--generation-status-target="activity"></span>
          <ol data-test-management--generation-status-target="steps">
            <li data-step="queued">Queue</li>
            <li data-step="preparing_source">Read source</li>
            <li data-step="waiting_for_model">Ask AI</li>
            <li data-step="writing_drafts">Write drafts</li>
          </ol>
          <div data-test-management--generation-status-target="progressContainer" hidden>
            <div data-test-management--generation-status-target="progressBar" class="ProgressBar">
              <span class="ProgressBar-item" style="width: 0%"></span>
            </div>
          </div>
          <button type="button" data-test-management--generation-status-target="cancelButton">Cancel</button>
          <button type="button" hidden data-test-management--generation-status-target="checkAgainButton">Check again</button>
          <button type="button" hidden data-test-management--generation-status-target="tryAgainButton">Try again</button>
        </div>
      </div>
    `);
    return ctx.getController<GenerationStatusController>('test-management--generation-status');
  }

  it('polls the status endpoint with JSON accept and CSRF headers', async () => {
    await mountPending();
    await waitFor(() => expect(fetchSpy).toHaveBeenCalled());

    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toBe('/status');
    expect(init).toMatchObject({
      method: 'GET',
      credentials: 'same-origin',
      headers: expect.objectContaining({
        Accept: 'application/json',
        'X-CSRF-Token': 'csrf-token-value',
      }),
    });
  });

  it('updates the banner with progress and shows the progress bar', async () => {
    await mountPending();
    await waitFor(() => expect(ctx.container.querySelector('[data-test-management--generation-status-target="message"]')?.textContent)
      .toContain('1 of 3'));

    const progress = ctx.container.querySelector<HTMLElement>('[data-test-management--generation-status-target="progressContainer"]')!;
    expect(progress.hidden).toBe(false);
    const item = progress.querySelector<HTMLElement>('.ProgressBar-item')!;
    expect(item.style.width).toBe('33%');

    const current = ctx.container.querySelector('[data-step="writing_drafts"]');
    expect(current?.classList.contains('is-current')).toBe(true);
    expect(ctx.container.querySelector('[data-step="queued"]')?.classList.contains('is-done')).toBe(true);
  });

  it('reloads the turbo frame and stops polling on success', async () => {
    fetchSpy
      .mockResolvedValueOnce(new Response(JSON.stringify({
        state: 'running',
        progress: { done: 0, total: 2 },
        message: 'Writing',
        started_at: null,
        updated_at: null,
        error: null,
      }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({
        state: 'succeeded',
        progress: { done: 2, total: 2 },
        message: '2 draft test cases ready',
        started_at: null,
        updated_at: null,
        error: null,
      }), { status: 200 }));

    await mountPending();
    await waitFor(() => expect(fetchSpy).toHaveBeenCalledTimes(1));
    await vi.advanceTimersByTimeAsync(2500);

    const frame = document.getElementById('tm-draft-results') as HTMLElement & { src?:string };
    await waitFor(() => expect(frame.getAttribute('src') ?? frame.src).toBe('/generations/1'));
    expect(frameReload).not.toHaveBeenCalled();
    expect(ctx.container.querySelector<HTMLElement>('[data-test-management--generation-status-target="banner"]')!.hidden)
      .toBe(true);

    const callsAfter = fetchSpy.mock.calls.length;
    await vi.advanceTimersByTimeAsync(10_000);
    expect(fetchSpy.mock.calls.length).toBe(callsAfter);
  });

  it('aborts in-flight requests on disconnect', async () => {
    let abortSignal:AbortSignal | undefined;
    fetchSpy.mockImplementation((_url, init) => {
      abortSignal = init!.signal!;
      return new Promise(() => undefined);
    });

    await mountPending();
    await waitFor(() => expect(abortSignal).toBeDefined());
    ctx.dispose();
    expect(abortSignal?.aborted).toBe(true);
  });
});
