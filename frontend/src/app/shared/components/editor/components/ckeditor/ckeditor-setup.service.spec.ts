// -- copyright
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

import { CKEditorSetupService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';

// watchTopLayer moves the ck-body-wrapper into the open dialog and back out on close.
describe('CKEditorSetupService#watchTopLayer', () => {
  const flushMutations = ():Promise<void> =>
    new Promise((resolve) => {
      window.setTimeout(resolve, 0);
    });

  const addWrapper = ():HTMLElement => {
    const wrapper = document.createElement('div');
    wrapper.classList.add('ck-body-wrapper');
    document.body.appendChild(wrapper);
    return wrapper;
  };

  // mirrors the turbo dialog dom: <dialog-helper><dialog>
  const openDialog = (id:string):HTMLDialogElement => {
    const helper = document.createElement('dialog-helper');
    const dialog = document.createElement('dialog');
    dialog.id = id;
    helper.appendChild(dialog);
    document.body.appendChild(helper);
    dialog.showModal();
    return dialog;
  };

  beforeAll(() => {
    // watchTopLayer uses no instance state, so call it on the prototype
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (CKEditorSetupService.prototype as any).watchTopLayer.call({});
  });

  afterEach(() => {
    document
      .querySelectorAll('.ck-body-wrapper, dialog-helper')
      .forEach((el) => el.remove());
  });

  it('moves an already-present body wrapper into a dialog opened afterwards', async () => {
    const wrapper = addWrapper();

    expect(wrapper.parentElement).toBe(document.body);

    const dialog = openDialog('create-work-package-dialog');
    await flushMutations();

    expect(wrapper.parentElement).toBe(dialog);
  });

  it('moves a wrapper created while a dialog is already open into that dialog', async () => {
    const dialog = openDialog('create-work-package-dialog');
    await flushMutations();

    const wrapper = addWrapper();
    await flushMutations();

    expect(wrapper.parentElement).toBe(dialog);
  });

  it('restores the wrapper to document.body when the dialog closes', async () => {
    const wrapper = addWrapper();
    const dialog = openDialog('create-work-package-dialog');
    await flushMutations();

    expect(wrapper.parentElement).toBe(dialog);

    dialog.close();
    await flushMutations();
    // closing removes the `open` attribute
    // the observer restores the wrapper on a microtask before teardown
    expect(wrapper.parentElement).toBe(document.body);
  });

  it('keeps the wrapper in the still-open dialog when a stacked inner dialog closes', async () => {
    const wrapper = addWrapper();
    const outer = openDialog('outer-dialog');
    await flushMutations();
    const inner = openDialog('inner-dialog');
    await flushMutations();

    expect(wrapper.parentElement).toBe(inner);

    inner.close();
    await flushMutations();

    expect(wrapper.parentElement).toBe(outer);

    outer.close();
    await flushMutations();

    expect(wrapper.parentElement).toBe(document.body);
  });
});
