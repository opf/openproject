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

import { Controller } from '@hotwired/stimulus';
import { updateObjectUrlPreview } from 'core-app/shared/helpers/images/object-url-preview';
import { setInputFiles } from 'core-app/shared/helpers/dom-helpers';

const DRAGGING_OVER = 'FormControl-file-field-drop-zone--dragging-over';
const HAS_PREVIEW = 'FormControl-file-field-wrap--has-preview';

export default class FileFieldController extends Controller<HTMLElement> {
  static targets = ['file', 'filename', 'dropBox', 'preview'];

  declare readonly fileTarget:HTMLInputElement;
  declare readonly filenameTarget:HTMLElement;
  declare readonly dropBoxTarget:HTMLButtonElement;
  declare readonly hasPreviewTarget:boolean;
  declare readonly previewTarget:HTMLImageElement;

  private previewUrl?:string;

  disconnect():void {
    this.previewUrl = updateObjectUrlPreview(this.previewUrl, undefined);
  }

  openFilePicker():void {
    this.fileTarget.click();
  }

  dragOver(event:DragEvent):void {
    event.preventDefault();
    this.dropBoxTarget.classList.add(DRAGGING_OVER);
  }

  dragLeave():void {
    this.dropBoxTarget.classList.remove(DRAGGING_OVER);
  }

  dropFile(event:DragEvent):void {
    event.preventDefault();
    this.dropBoxTarget.classList.remove(DRAGGING_OVER);

    const file = event.dataTransfer?.files?.[0];
    if (!file) { return; }

    // A drop lands on the drop zone, not the hidden input, but only the input's value gets
    // submitted — so we copy the file onto it. Firing a real 'change' event (instead of calling
    // fileChosen() directly) makes a drop behave exactly like picking a file natively, so other
    // listeners on the input, e.g. auto-submit, run as well.
    setInputFiles(this.fileTarget, file);
    this.fileTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  fileChosen():void {
    const file = this.fileTarget.files?.[0];
    this.filenameTarget.textContent = file ? file.name : this.filenameTarget.dataset.empty ?? '';
    this.updatePreview(file);
  }

  private updatePreview(file?:File):void {
    if (!this.hasPreviewTarget) { return; }

    const isImage = !!file && file.type.startsWith('image/');
    this.previewUrl = updateObjectUrlPreview(this.previewUrl, isImage ? file : undefined);

    if (this.previewUrl) {
      this.previewTarget.src = this.previewUrl;
    } else {
      this.previewTarget.removeAttribute('src');
    }

    this.element.classList.toggle(HAS_PREVIEW, !!this.previewUrl);
  }
}
