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
import WorkflowCheckboxStateController from './workflow-checkbox-state.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('Admin workflow checkbox state controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;
  let originalOpenProject:typeof window.OpenProject;
  let dialog:HTMLDialogElement;
  let saveButton:HTMLButtonElement;
  let navigate:Mock;

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'token-123';
    document.head.appendChild(csrfMeta);

    // isDirtyValueChanged mirrors dirtiness into window.OpenProject.pageState.
    originalOpenProject = window.OpenProject;
    window.OpenProject = { pageState: 'pristine' } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'admin--workflow-checkbox-state': WorkflowCheckboxStateController },
    });
    await ctx.mount(`
      <form>
        <div data-controller="admin--workflow-checkbox-state"
             data-admin--workflow-checkbox-state-save-url-value="/types/1/workflow/matrix?tab=always"
             data-admin--workflow-checkbox-state-variant-id-value="type-1"
             data-admin--workflow-checkbox-state-has-checkbox-changes-value="true">
          <input type="hidden" name="role_ids[]" value="3">
          <input type="checkbox" name="status[1][2]" value="always" data-old-status="1" data-new-status="2" checked>
          <input type="checkbox" name="status[2][1]" value="always" data-old-status="2" data-new-status="1">
          <dialog data-admin--workflow-checkbox-state-target="confirmationDialog">
            <button type="button" data-admin--workflow-checkbox-state-target="ignoreButton">Ignore</button>
            <button type="button" data-admin--workflow-checkbox-state-target="saveButton">Save</button>
          </dialog>
        </div>
      </form>
    `);

    dialog = ctx.container.querySelector('dialog')!;
    saveButton = ctx.container.querySelector('[data-admin--workflow-checkbox-state-target="saveButton"]')!;
    navigate = vi.fn();
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    sessionStorage.clear();
    target.remove();
    csrfMeta.remove();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const lastCall = () => fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers, body:FormData }];
  const controller = () => ctx.getController<WorkflowCheckboxStateController>('admin--workflow-checkbox-state');

  function saveFromDialog() {
    controller().confirmNavigation(navigate);
    expect(dialog.open).toBe(true);
    saveButton.click();
  }

  it('patches only the checked transitions as form data', async () => {
    saveFromDialog();

    await waitFor(() => { expect(navigate).toHaveBeenCalledOnce(); });
    const [url, init] = lastCall();
    expect(url).toBe('/types/1/workflow/matrix?tab=always');
    expect(init.method).toBe('PATCH');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.get('X-CSRF-Token')).toBe('token-123');
    expect(init.body).toBeInstanceOf(FormData);
    expect(init.body.getAll('role_ids[]')).toEqual(['3']);
    expect(init.body.get('status[1][2]')).toBe('always');
    expect(init.body.has('status[2][1]')).toBe(false);
  });

  it('renders the stream, closes the dialog and navigates on success', async () => {
    saveFromDialog();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await waitFor(() => { expect(navigate).toHaveBeenCalledOnce(); });
    expect(dialog.open).toBe(false);
    expect(window.OpenProject.pageState).toBe('pristine');
  });

  it.each([422, 500])('renders an HTTP %i stream once and keeps the dialog open', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));

    saveFromDialog();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
    expect(navigate).not.toHaveBeenCalled();
    expect(dialog.open).toBe(true);
    expect(window.OpenProject.pageState).toBe('edited');
  });

  it('treats a non-stream success as stored without rendering', async () => {
    fetchSpy.mockResolvedValueOnce(htmlResponse());

    saveFromDialog();

    await waitFor(() => { expect(navigate).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
    expect(dialog.open).toBe(false);
  });

  it('navigates straight away when nothing is dirty', async () => {
    controller().hasCheckboxChangesValue = false;
    await ctx.nextFrame();

    controller().confirmNavigation(navigate);

    expect(navigate).toHaveBeenCalledOnce();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
