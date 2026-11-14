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

import { BlockNoteEditor, PartialBlock } from '@blocknote/core';
import { FailedUploadCleanupExtension } from './failed-upload-cleanup';

const UPLOADED_URL = 'https://openproject.example/attachments/1/content';

const cleanups:(() => void)[] = [];

function mountEditor(uploadFile:(file:File) => Promise<string>, initialContent?:PartialBlock[]) {
  const container = document.createElement('div');
  document.body.appendChild(container);
  const editor = BlockNoteEditor.create({ initialContent, uploadFile, extensions: [FailedUploadCleanupExtension] });
  editor.mount(container);
  cleanups.push(() => {
    editor.unmount();
    container.remove();
  });

  return { editor, container };
}

function filesTransfer():DataTransfer {
  const transfer = new DataTransfer();
  transfer.items.add(new File(['content'], 'notes.odt', { type: 'application/vnd.oasis.opendocument.text' }));
  return transfer;
}

function dropFile(container:HTMLElement):void {
  const target = container.querySelector('.bn-block-content')!;
  const { left, top } = target.getBoundingClientRect();
  target.dispatchEvent(new DragEvent('drop', {
    dataTransfer: filesTransfer(), clientX: left + 5, clientY: top + 2, bubbles: true, cancelable: true,
  }));
}

function pasteFile(editor:BlockNoteEditor):void {
  editor.prosemirrorView.dom.dispatchEvent(new ClipboardEvent('paste', {
    clipboardData: filesTransfer(), bubbles: true, cancelable: true,
  }));
}

const settled = () => new Promise((resolve) => { setTimeout(resolve, 50); });
const blockTypes = (editor:BlockNoteEditor) => editor.document.map((block) => block.type);

describe('FailedUploadCleanupExtension', () => {
  afterEach(() => {
    cleanups.splice(0).forEach((cleanup) => cleanup());
  });

  it('removes the placeholder of a dropped file whose upload failed', async () => {
    const { editor, container } = mountEditor(() => Promise.resolve(''), [{ type: 'paragraph', content: 'Text' }]);

    dropFile(container);
    await settled();

    expect(blockTypes(editor)).toEqual(['paragraph']);
    expect(container.querySelector('.bn-file-loading-preview')).toBeNull();
  });

  it('keeps the block of a dropped file that was uploaded', async () => {
    const { editor, container } = mountEditor(() => Promise.resolve(UPLOADED_URL), [{ type: 'paragraph', content: 'Text' }]);

    dropFile(container);
    await settled();

    expect(editor.document.find((block) => block.type === 'file')?.props).toMatchObject({ url: UPLOADED_URL });
  });

  it('removes the placeholder of a pasted file whose upload failed', async () => {
    const { editor, container } = mountEditor(() => Promise.resolve(''), [{ type: 'paragraph' }]);
    editor.focus();

    pasteFile(editor);
    await settled();

    expect(blockTypes(editor)).not.toContain('file');
    expect(container.querySelector('.bn-file-loading-preview')).toBeNull();
  });

  it('keeps the block of a file panel upload that failed, which offers to add a file again', async () => {
    const { editor, container } = mountEditor(() => Promise.resolve(''), [{ id: 'image', type: 'image' }, { type: 'paragraph' }]);
    const file = new File(['content'], 'photo.png', { type: 'image/png' });

    const url = await editor.uploadFile!(file, 'image');
    editor.updateBlock('image', { props: { name: file.name, url: url as string } });
    await settled();

    expect(blockTypes(editor)).toEqual(['image', 'paragraph']);
    expect(container.querySelector('.bn-add-file-button')).not.toBeNull();
  });

  it('leaves an empty file block nobody uploaded to', async () => {
    const { editor } = mountEditor(() => Promise.resolve(''), [{ type: 'file' }, { type: 'paragraph' }]);

    await settled();

    expect(blockTypes(editor)).toEqual(['file', 'paragraph']);
  });

  it('does nothing once the editor is gone', async () => {
    let finishUpload:((url:string) => void)|undefined;
    const { container } = mountEditor(() => new Promise((resolve) => { finishUpload = resolve; }), [{ type: 'paragraph' }]);
    dropFile(container);

    cleanups.splice(0).forEach((cleanup) => cleanup());
    finishUpload!('');

    await expect(settled()).resolves.toBeUndefined();
  });
});
