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
import { userEvent } from 'vitest/browser';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import WorkflowCheckboxStateController from './workflow-checkbox-state.controller';
import WorkflowTabSelectController from './workflow-tab-select.controller';

const FRAME_SRC = '/workflows/edit?tab=always&role_ids%5B%5D=3&status_ids%5B%5D=9';
const AUTHOR_TAB_URL = '/workflows/edit?tab=author&role_ids%5B%5D=3';
const COPY_URL = '/workflows/copy';

describe('Workflow checkbox state controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:MockInstance<typeof window.fetch>;
  let pushStateSpy:MockInstance<typeof history.pushState>;
  let csrfMeta:HTMLMetaElement;
  let originalOpenProject:typeof window.OpenProject;
  let copyClicks:number;

  const countCopyClicks = (event:MouseEvent) => {
    const link = (event.target as HTMLElement).closest('a');
    if (link?.getAttribute('href') !== COPY_URL) return;

    event.preventDefault();
    copyClicks += 1;
  };

  beforeEach(async () => {
    copyClicks = 0;
    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'csrf-token-value';
    document.head.append(csrfMeta);
    originalOpenProject = window.OpenProject;
    window.OpenProject = {} as typeof window.OpenProject;
    fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue(new Response('', { status: 200 }));
    pushStateSpy = vi.spyOn(history, 'pushState').mockImplementation(() => undefined);
    document.addEventListener('click', countCopyClicks);

    ctx = await setupStimulusTest({
      controllers: {
        'admin--workflow-checkbox-state': WorkflowCheckboxStateController,
        'admin--workflow-tab-select': WorkflowTabSelectController,
      },
    });
  });

  afterEach(() => {
    ctx?.dispose();
    document.removeEventListener('click', countCopyClicks);
    csrfMeta.remove();
    window.OpenProject = originalOpenProject;
    sessionStorage.clear();
    vi.restoreAllMocks();
  });

  async function renderMatrix({ hasStatusChanges = false } = {}) {
    await ctx.mount(`
      <turbo-frame id="workflow-frame" disabled src="${FRAME_SRC}">
        <a href="${AUTHOR_TAB_URL}" data-turbo="false"
           data-controller="admin--workflow-tab-select"
           data-admin--workflow-tab-select-tab-value="author"
           data-admin--workflow-tab-select-admin--workflow-checkbox-state-outlet="#workflow-matrix"
           data-action="admin--workflow-tab-select#select">Author</a>
        <form>
          <div id="workflow-matrix"
               data-controller="admin--workflow-checkbox-state"
               data-admin--workflow-checkbox-state-save-url-value="/workflows/matrix"
               data-admin--workflow-checkbox-state-variant-id-value="7"
               data-admin--workflow-checkbox-state-has-status-changes-value="${hasStatusChanges}">
            <input type="hidden" name="role_ids[]" value="3">
            <label>
              New to Closed
              <input type="checkbox" name="status[1][2][]" value="always" checked
                     data-old-status="1" data-new-status="2">
            </label>
            <label>
              New to Rejected
              <input type="checkbox" name="status[1][3][]" value="always"
                     data-old-status="1" data-new-status="3">
            </label>
            <dialog data-admin--workflow-checkbox-state-target="confirmationDialog">
              <button type="button" data-admin--workflow-checkbox-state-target="ignoreButton">Ignore changes</button>
              <button type="button" data-admin--workflow-checkbox-state-target="saveButton">Save changes and continue</button>
            </dialog>
          </div>
        </form>
        <a href="${COPY_URL}" data-turbo="false" data-admin--workflow-checkbox-state-confirmation-trigger>Copy</a>
      </turbo-frame>
    `);
  }

  const absoluteUrl = (path:string) => new URL(path, window.location.origin).toString();
  const dialog = () => ctx.container.querySelector('dialog')!;
  const frame = () => ctx.container.querySelector('turbo-frame')!;

  async function makeMatrixDirty() {
    await userEvent.click(ctx.screen.getByRole('checkbox', { name: 'New to Closed' }));
  }

  describe('when following the copy link', () => {
    it('follows the link without a dialog when nothing changed', async () => {
      await renderMatrix();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Copy' }));

      expect(dialog().open).toBe(false);
      expect(copyClicks).toBe(1);
    });

    it('saves the pending changes and then follows the link', async () => {
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Copy' }));
      expect(dialog().open).toBe(true);
      expect(copyClicks).toBe(0);

      await userEvent.click(ctx.screen.getByRole('button', { name: 'Save changes and continue' }));

      await waitFor(() => { expect(dialog().open).toBe(false); });
      const [url, request] = fetchSpy.mock.calls[0];
      expect(url).toBe('/workflows/matrix');
      expect(request?.method).toBe('PATCH');
      expect((request?.headers as Record<string, string>)['X-CSRF-Token']).toBe('csrf-token-value');
      const body = request?.body as FormData;
      expect(body.getAll('role_ids[]')).toEqual(['3']);
      expect(body.has('status[1][2][]')).toBe(false);
      await waitFor(() => { expect(copyClicks).toBe(1); }, { timeout: 2000 });
    });

    it('follows the re-rendered link after saving the pending changes', async () => {
      await renderMatrix();
      await makeMatrixDirty();
      await userEvent.click(ctx.screen.getByRole('link', { name: 'Copy' }));
      await userEvent.click(ctx.screen.getByRole('button', { name: 'Save changes and continue' }));
      await waitFor(() => { expect(dialog().open).toBe(false); });

      const staleLink = ctx.screen.getByRole('link', { name: 'Copy' });
      const liveLink = staleLink.cloneNode(true) as HTMLAnchorElement;
      staleLink.replaceWith(liveLink);
      const liveLinkClicked = vi.fn();
      liveLink.addEventListener('click', liveLinkClicked);
      const staleLinkClicked = vi.fn((event:Event) => event.preventDefault());
      staleLink.addEventListener('click', staleLinkClicked);

      await waitFor(() => { expect(liveLinkClicked).toHaveBeenCalled(); }, { timeout: 2000 });
      expect(staleLinkClicked).not.toHaveBeenCalled();
    });

    it('drops the pending status selection when ignoring the changes and then follows the link', async () => {
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Copy' }));
      await userEvent.click(ctx.screen.getByRole('button', { name: 'Ignore changes' }));

      expect(dialog().open).toBe(false);
      const reloaded = new URL(frame().getAttribute('src')!, window.location.origin);
      expect(reloaded.pathname).toBe('/workflows/edit');
      expect(reloaded.searchParams.get('tab')).toBe('always');
      expect(reloaded.searchParams.getAll('role_ids[]')).toEqual(['3']);
      expect(reloaded.searchParams.has('status_ids[]')).toBe(false);
      expect(fetchSpy).not.toHaveBeenCalled();
      await waitFor(() => { expect(copyClicks).toBe(1); }, { timeout: 2000 });
    });

    it('keeps the dialog open and does not follow the link when saving fails', async () => {
      fetchSpy.mockResolvedValue(new Response('', { status: 422 }));
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Copy' }));
      await userEvent.click(ctx.screen.getByRole('button', { name: 'Save changes and continue' }));
      await new Promise((resolve) => { setTimeout(resolve, 1200); });

      expect(fetchSpy).toHaveBeenCalled();
      expect(dialog().open).toBe(true);
      expect(copyClicks).toBe(0);
    });
  });

  describe('when switching the tab', () => {
    it('switches without a dialog when nothing changed', async () => {
      await renderMatrix();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));

      expect(dialog().open).toBe(false);
      expect(frame().getAttribute('src')).toBe(absoluteUrl(AUTHOR_TAB_URL));
    });

    it('asks for confirmation when a status was added or removed', async () => {
      await renderMatrix({ hasStatusChanges: true });

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));

      expect(dialog().open).toBe(true);
      expect(frame().getAttribute('src')).toBe(FRAME_SRC);
    });

    it('stays on the tab and keeps the changes when the dialog is closed', async () => {
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));
      dialog().close();

      expect(frame().getAttribute('src')).toBe(FRAME_SRC);
      expect(pushStateSpy).not.toHaveBeenCalled();
      expect(ctx.screen.getByRole('checkbox', { name: 'New to Closed' })).not.toBeChecked();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));
      expect(dialog().open).toBe(true);
    });

    it('saves the pending changes before it switches', async () => {
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));
      expect(frame().getAttribute('src')).toBe(FRAME_SRC);

      await userEvent.click(ctx.screen.getByRole('button', { name: 'Save changes and continue' }));

      await waitFor(() => { expect(frame().getAttribute('src')).toBe(absoluteUrl(AUTHOR_TAB_URL)); });
      expect(fetchSpy).toHaveBeenCalledTimes(1);
      expect(dialog().open).toBe(false);
      const historyUrl = new URL(pushStateSpy.mock.calls[0][2] as string);
      expect(historyUrl.searchParams.get('tab')).toBe('author');
    });

    it('discards the pending changes and switches when ignoring them', async () => {
      await renderMatrix();
      await makeMatrixDirty();

      await userEvent.click(ctx.screen.getByRole('link', { name: 'Author' }));
      await userEvent.click(ctx.screen.getByRole('button', { name: 'Ignore changes' }));

      await waitFor(() => { expect(frame().getAttribute('src')).toBe(absoluteUrl(AUTHOR_TAB_URL)); });
      expect(fetchSpy).not.toHaveBeenCalled();
      expect(dialog().open).toBe(false);
    });
  });
});
