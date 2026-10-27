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

import { vi } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FileFieldControllerType from './file-field.controller';

const IDENTIFIER = 'file-field';
const DRAGGING_OVER = 'FormControl-file-field-drop-zone--dragging-over';
const DRAGGING_OVER_FORBIDDEN = 'FormControl-file-field-drop-zone--dragging-over-forbidden';
const HAS_PREVIEW = 'FormControl-file-field-wrap--has-preview';

describe('File field controller', () => {
  let ctx:StimulusTestContext;
  let FileFieldController:typeof FileFieldControllerType;

  beforeAll(async () => {
    ({ default: FileFieldController } = await import('./file-field.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { [IDENTIFIER]: FileFieldController } });
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function mount(accept = '') {
    await ctx.mount(`
      <div data-controller="${IDENTIFIER}">
        <input type="file" hidden
               accept="${accept}"
               data-${IDENTIFIER}-target="file"
               data-action="change->${IDENTIFIER}#fileChosen">

        <button type="button"
                data-${IDENTIFIER}-target="dropBox"
                data-action="click->${IDENTIFIER}#openFilePicker
                             dragover->${IDENTIFIER}#dragOver
                             dragleave->${IDENTIFIER}#dragLeave
                             drop->${IDENTIFIER}#dropFile">
          <span class="FormControl-file-field-placeholder">
            <svg></svg>
            <span data-${IDENTIFIER}-target="filename"
                  data-empty="Upload file">Upload file</span>
          </span>
          <img data-${IDENTIFIER}-target="preview">
        </button>
      </div>`);
  }

  const target = (name:string) => ctx.container.querySelector<HTMLElement>(`[data-${IDENTIFIER}-target="${name}"]`)!;
  const fileInput = () => target('file') as HTMLInputElement;
  const dropBox = () => target('dropBox');
  const preview = () => target('preview') as HTMLImageElement;
  const wrap = () => ctx.container.querySelector<HTMLElement>(`[data-controller="${IDENTIFIER}"]`)!;

  function file(name = 'contract.pdf') {
    return new File(['content'], name, { type: 'application/pdf' });
  }

  function imageFile(name = 'logo.png') {
    return new File(['content'], name, { type: 'image/png' });
  }

  async function choose(chosenFile:File) {
    const transfer = new DataTransfer();
    transfer.items.add(chosenFile);
    fileInput().files = transfer.files;
    fileInput().dispatchEvent(new Event('change', { bubbles: true }));
    await ctx.nextFrame();
  }

  it('opens the native file picker when the drop zone is clicked', async () => {
    await mount();
    const clickSpy = vi.spyOn(fileInput(), 'click');

    dropBox().dispatchEvent(new MouseEvent('click', { bubbles: true }));

    expect(clickSpy).toHaveBeenCalledOnce();
  });

  it('shows the chosen file name in place of the placeholder label', async () => {
    await mount();
    const transfer = new DataTransfer();
    transfer.items.add(file());
    fileInput().files = transfer.files;

    fileInput().dispatchEvent(new Event('change', { bubbles: true }));
    await ctx.nextFrame();

    expect(target('filename').textContent).toEqual('contract.pdf');
  });

  it('restores the placeholder label once the file list is empty again', async () => {
    await mount();
    const transfer = new DataTransfer();
    transfer.items.add(file());
    fileInput().files = transfer.files;
    fileInput().dispatchEvent(new Event('change', { bubbles: true }));
    await ctx.nextFrame();

    fileInput().files = new DataTransfer().files;
    fileInput().dispatchEvent(new Event('change', { bubbles: true }));
    await ctx.nextFrame();

    expect(target('filename').textContent).toEqual('Upload file');
  });

  it('highlights the drop zone while dragging over it, and clears it on drag leave', async () => {
    await mount();

    dropBox().dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true }));
    expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(true);

    dropBox().dispatchEvent(new DragEvent('dragleave', { bubbles: true, cancelable: true }));
    expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(false);
  });

  it('puts a dropped file on the hidden input and shows its name', async () => {
    await mount();
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file());

    dropBox().dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
    await ctx.nextFrame();

    expect(fileInput().files?.[0].name).toEqual('contract.pdf');
    expect(target('filename').textContent).toEqual('contract.pdf');
    expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(false);
  });

  it('fires a real change event on drop, so other listeners on the input (e.g. auto-submit) run too', async () => {
    await mount();
    const changeListener = vi.fn();
    fileInput().addEventListener('change', changeListener);
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file());

    dropBox().dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
    await ctx.nextFrame();

    expect(changeListener).toHaveBeenCalledOnce();
  });

  describe('restricting dropped files to the accept attribute', () => {
    it('ignores a dropped file that does not match an image/* accept pattern', async () => {
      await mount('image/*');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file());

      dropBox().dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
      await ctx.nextFrame();

      expect(fileInput().files?.length).toEqual(0);
      expect(target('filename').textContent).toEqual('Upload file');
    });

    it('accepts a dropped file that matches an exact MIME type in a comma-separated list', async () => {
      await mount('image/png, image/jpg');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(imageFile());

      dropBox().dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
      await ctx.nextFrame();

      expect(fileInput().files?.[0].name).toEqual('logo.png');
    });

    it('rejects a dropped file that does not match any exact MIME type in a comma-separated list', async () => {
      await mount('image/png, image/jpg');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file());

      dropBox().dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer }));
      await ctx.nextFrame();

      expect(fileInput().files?.length).toEqual(0);
    });
  });

  describe('previewing whether a dragged-over file will be accepted', () => {
    it('grays out the drop zone and shows a forbidden cursor while hovering a file that does not match the accept attribute', async () => {
      await mount('image/*');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file());

      dropBox().dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer }));

      expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(false);
      expect(dropBox().classList.contains(DRAGGING_OVER_FORBIDDEN)).toBe(true);
    });

    it('highlights the drop zone while hovering a file that matches the accept attribute', async () => {
      await mount('image/*');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(imageFile());

      dropBox().dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer }));

      expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(true);
      expect(dropBox().classList.contains(DRAGGING_OVER_FORBIDDEN)).toBe(false);
    });

    it('stays permissive while hovering, since the dragged file\'s name is unknown before drop', async () => {
      await mount('.ttf');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file());

      dropBox().dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer }));

      expect(dropBox().classList.contains(DRAGGING_OVER)).toBe(true);
      expect(dropBox().classList.contains(DRAGGING_OVER_FORBIDDEN)).toBe(false);
    });

    it('clears the forbidden styling on drag leave', async () => {
      await mount('image/*');
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file());
      dropBox().dispatchEvent(new DragEvent('dragover', { bubbles: true, cancelable: true, dataTransfer }));

      dropBox().dispatchEvent(new DragEvent('dragleave', { bubbles: true, cancelable: true }));

      expect(dropBox().classList.contains(DRAGGING_OVER_FORBIDDEN)).toBe(false);
    });
  });

  describe('previewing an image', () => {
    it('shows the chosen image and hides the icon/label/caption placeholder', async () => {
      await mount();

      await choose(imageFile());

      expect(preview().src).toMatch(/^blob:/);
      expect(wrap().classList.contains(HAS_PREVIEW)).toBe(true);
    });

    it('keeps the placeholder visible for a file that is not an image', async () => {
      await mount();

      await choose(file());

      expect(wrap().classList.contains(HAS_PREVIEW)).toBe(false);
    });

    it('revokes the previous preview URL once a new file replaces it', async () => {
      await mount();
      const revokeSpy = vi.spyOn(URL, 'revokeObjectURL');
      await choose(imageFile('first.png'));
      const firstUrl = preview().src;

      await choose(imageFile('second.png'));

      expect(revokeSpy).toHaveBeenCalledWith(firstUrl);
      expect(preview().src).not.toEqual(firstUrl);
    });

    it('hides the preview and restores the placeholder once the file list is empty again', async () => {
      await mount();
      await choose(imageFile());

      fileInput().files = new DataTransfer().files;
      fileInput().dispatchEvent(new Event('change', { bubbles: true }));
      await ctx.nextFrame();

      expect(wrap().classList.contains(HAS_PREVIEW)).toBe(false);
    });
  });
});
