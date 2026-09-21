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

import { Controller } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';

const DRAGGING_OVER = 'op-file-section--drop-box_dragging-over';
const POLLING_INTERVAL = 2000;

export default class CsvImportController extends Controller<HTMLElement> {
  static targets = ['submit', 'dryRun', 'file', 'filename', 'dropBox', 'sizeError', 'poll', 'finished'];

  static values = { maxSize: Number, tooLarge: String };

  declare readonly submitTarget:HTMLButtonElement;
  declare readonly dryRunTarget:HTMLInputElement;
  declare readonly fileTarget:HTMLInputElement;
  declare readonly filenameTarget:HTMLElement;
  declare readonly dropBoxTarget:HTMLButtonElement;
  declare readonly sizeErrorTarget:HTMLElement;
  declare readonly maxSizeValue:number;
  declare readonly tooLargeValue:string;

  interval?:ReturnType<typeof setInterval>;

  pollTargetConnected(element:HTMLElement) {
    const url = element.dataset.url;
    if (!url) { return; }

    this.interval ??= setInterval(() => { void this.refresh(url); }, POLLING_INTERVAL);
  }

  pollTargetDisconnected() {
    this.stopPolling();
  }

  finishedTargetConnected() {
    this.stopPolling();
  }

  disconnect() {
    this.stopPolling();
  }

  clear(event:MouseEvent) {
    event.preventDefault();

    const link = event.currentTarget as HTMLAnchorElement;

    void this.reset(link.href, link.dataset.streamUrl ?? link.href);
  }

  openFilePicker() {
    this.fileTarget.click();
  }

  dragOver(event:DragEvent) {
    event.preventDefault();
    this.dropBoxTarget.classList.add(DRAGGING_OVER);
  }

  dragLeave() {
    this.dropBoxTarget.classList.remove(DRAGGING_OVER);
  }

  dropFile(event:DragEvent) {
    event.preventDefault();
    this.dropBoxTarget.classList.remove(DRAGGING_OVER);

    const file = event.dataTransfer?.files?.[0];
    if (!file) { return; }

    // The form submits the input, not the drop event, so the dropped file has to be put there.
    const transfer = new DataTransfer();
    transfer.items.add(file);
    this.fileTarget.files = transfer.files;

    this.fileChosen();
  }

  fileChosen() {
    const file = this.fileTarget.files?.[0];

    this.filenameTarget.textContent = file ? file.name : this.filenameTarget.dataset.empty ?? '';
    this.checkFile(file);
  }

  nameTheAction() {
    const { checkLabel, importLabel } = this.submitTarget.dataset;
    const label = this.dryRunTarget.checked ? checkLabel : importLabel;

    if (label) {
      this.submitTarget.textContent = label;
    }
  }

  private async refresh(url:string) {
    const response = await fetch(url, {
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    });

    if (response.ok) {
      Turbo.renderStreamMessage(await response.text());
    } else {
      this.stopPolling();
    }
  }

  private async reset(url:string, streamUrl:string) {
    const response = await fetch(streamUrl, {
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    });

    if (!response.ok) {
      window.location.href = url;
      return;
    }

    Turbo.renderStreamMessage(await response.text());
    // The report is gone, so reloading must not bring it back.
    window.history.replaceState({}, '', url);
  }

  // The size is refused here so a file far over the limit is never sent only to be turned away;
  // the server refuses it again, which is what actually decides.
  private checkFile(file:File|undefined) {
    const tooLarge = !!file && this.maxSizeValue > 0 && file.size > this.maxSizeValue;

    this.sizeErrorTarget.textContent = tooLarge ? this.tooLargeValue : '';
    this.sizeErrorTarget.hidden = !tooLarge;
    this.submitTarget.disabled = !file || tooLarge;
  }

  private stopPolling() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = undefined;
    }
  }
}
