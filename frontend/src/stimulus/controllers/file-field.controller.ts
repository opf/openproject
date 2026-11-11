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
const DRAGGING_OVER_FORBIDDEN = 'FormControl-file-field-drop-zone--dragging-over-forbidden';
const HAS_PREVIEW = 'FormControl-file-field-wrap--has-preview';

export default class FileFieldController extends Controller<HTMLElement> {
  static targets = ['file', 'filename', 'dropBox', 'preview', 'error', 'tooLarge'];

  static values = { maxSize: Number };

  declare readonly fileTarget:HTMLInputElement;
  declare readonly filenameTarget:HTMLElement;
  declare readonly dropBoxTarget:HTMLButtonElement;
  declare readonly hasPreviewTarget:boolean;
  declare readonly previewTarget:HTMLImageElement;
  declare readonly hasErrorTarget:boolean;
  declare readonly errorTarget:HTMLElement;
  declare readonly hasTooLargeTarget:boolean;
  declare readonly tooLargeTarget:HTMLElement;
  declare readonly maxSizeValue:number;

  private previewUrl?:string;

  disconnect():void {
    this.previewUrl = updateObjectUrlPreview(this.previewUrl, undefined);
  }

  openFilePicker():void {
    this.fileTarget.click();
  }

  dragOver(event:DragEvent):void {
    event.preventDefault();

    const accepted = this.isAcceptedType(event.dataTransfer?.items?.[0]?.type);
    this.dropBoxTarget.classList.toggle(DRAGGING_OVER, accepted);
    this.dropBoxTarget.classList.toggle(DRAGGING_OVER_FORBIDDEN, !accepted);

    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = accepted ? 'copy' : 'none';
    }
  }

  dragLeave():void {
    this.dropBoxTarget.classList.remove(DRAGGING_OVER, DRAGGING_OVER_FORBIDDEN);
  }

  dropFile(event:DragEvent):void {
    event.preventDefault();
    this.dropBoxTarget.classList.remove(DRAGGING_OVER, DRAGGING_OVER_FORBIDDEN);

    const file = event.dataTransfer?.files?.[0];
    if (!file) { return; }

    if (!this.isAcceptedFile(file)) {
      this.showError();
      return;
    }

    if (!this.isWithinSizeLimit(file)) {
      this.showTooLarge();
      return;
    }

    // A drop lands on the drop zone, not the hidden input, but only the input's value gets
    // submitted — so we copy the file onto it. Firing a real 'change' event (instead of calling
    // fileChosen() directly) makes a drop behave exactly like picking a file natively, so other
    // listeners on the input, e.g. auto-submit, run as well.
    setInputFiles(this.fileTarget, file);
    this.fileTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  private acceptPatterns():string[] {
    return this.fileTarget.accept
      .split(',')
      .map((pattern) => pattern.trim())
      .filter(Boolean);
  }

  // Unlike choosing a file through the native picker, a browser never filters a drag-and-drop
  // payload against the input's `accept` attribute, so we have to check it ourselves.
  private isAcceptedFile(file:File):boolean {
    const patterns = this.acceptPatterns();
    if (patterns.length === 0) { return true; }

    return patterns.some((pattern) => {
      if (pattern.startsWith('.')) {
        return file.name.toLowerCase().endsWith(pattern.toLowerCase());
      }

      return this.matchesMimePattern(pattern, file.type);
    });
  }

  // During dragover the browser only exposes the dragged item's MIME type (guessed from its
  // extension), never the File itself — the name is withheld until drop. So an accept pattern
  // that is itself an extension (e.g. ".ttf") can't be checked yet; we stay permissive for those
  // and let dropFile's isAcceptedFile do the authoritative check once the file is known.
  private isAcceptedType(type?:string):boolean {
    const typePatterns = this.acceptPatterns().filter((pattern) => !pattern.startsWith('.'));
    if (typePatterns.length === 0) { return true; }

    return !!type && typePatterns.some((pattern) => this.matchesMimePattern(pattern, type));
  }

  private matchesMimePattern(pattern:string, type:string):boolean {
    return pattern.endsWith('/*') ? type.startsWith(pattern.slice(0, -1)) : type === pattern;
  }

  // Browsers never enforce a maximum file size, picker or drop alike, so this is the only check
  // of its own kind (unlike accept, there is no native behavior to fall back on).
  private isWithinSizeLimit(file:File):boolean {
    return this.maxSizeValue <= 0 || file.size <= this.maxSizeValue;
  }

  // A native file picker already filters by `accept`, but it can be bypassed (e.g. an "All
  // Files" option), so this re-validates — consistently with dropFile(), regardless of whether
  // the caller rendered an error message (only *showing* feedback is opt-in, see showError()).
  // stopImmediatePropagation() keeps a rejection from reaching other change listeners on the
  // same input, e.g. auto-submit, which would otherwise submit the form with the file we just
  // cleared.
  fileChosen(event:Event):void {
    const file = this.fileTarget.files?.[0];

    if (file && !this.isAcceptedFile(file)) {
      event.stopImmediatePropagation();
      this.fileTarget.value = '';
      this.showError();
      return;
    }

    if (file && !this.isWithinSizeLimit(file)) {
      event.stopImmediatePropagation();
      this.fileTarget.value = '';
      this.showTooLarge();
      return;
    }

    this.clearErrors();
    this.filenameTarget.textContent = file ? file.name : this.filenameTarget.dataset.empty ?? '';
    this.updatePreview(file);
  }

  private showError():void {
    if (this.hasErrorTarget) this.errorTarget.hidden = false;
  }

  private showTooLarge():void {
    if (this.hasTooLargeTarget) this.tooLargeTarget.hidden = false;
  }

  private clearErrors():void {
    if (this.hasErrorTarget) this.errorTarget.hidden = true;
    if (this.hasTooLargeTarget) this.tooLargeTarget.hidden = true;
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
