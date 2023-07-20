/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import * as Turbo from "@hotwired/turbo"
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    cancelUrl: String,
  }
  declare cancelUrlValue: string

  static targets = [ "titleInput", "clarificationNeedInput", "clarificationInput", "workPackageInput", "workPackageButton", "detailsInput"]
  declare readonly titleInputTarget: HTMLInputElement
  declare readonly clarificationNeedInputTarget: HTMLInputElement
  declare readonly clarificationInputTarget: HTMLInputElement
  declare readonly detailsInputTarget: HTMLInputElement
  declare readonly workPackageInputTarget: HTMLInputElement
  declare readonly workPackageButtonTarget: HTMLInputElement

  connect(): void {
    this.focusInput();
  }

  focusInput(): void {
    const input = this.element.querySelector('input[name="meeting_agenda_item[title]"]');
    if(input) {
      (input as HTMLInputElement).focus();
    }
  }

  async cancel() {
    const confirmed = confirm("Are you sure?");
    if (!confirmed) {
      return;
    }
    const response = await fetch(this.cancelUrlValue, {
      method: "GET",
      headers: {
        'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
        'Accept': 'text/vnd.turbo-stream.html',
      },
      credentials: 'same-origin',
    });

    if (response.ok) {
      const text = await response.text();
      Turbo.renderStreamMessage(text);
    }
  }

  async addClarificationNeed() {
    this.clarificationNeedInputTarget.classList.remove("d-none");
    const textarea = this.element.querySelector('textarea[name="meeting_agenda_item[input]"]');
    setTimeout(() => {
      if(textarea) {
        (textarea as HTMLInputElement).focus();
      }
    }, 100);
  }

  async addClarification() {
    this.clarificationInputTarget.classList.remove("d-none");
    const textarea = this.element.querySelector('textarea[name="meeting_agenda_item[output]"]');
    setTimeout(() => {
      if(textarea) {
        (textarea as HTMLInputElement).focus();
      }
    }, 100);
  }

  async addDetails() {
    this.detailsInputTarget.classList.remove("d-none");
    const textarea = this.element.querySelector('textarea[name="meeting_agenda_item[details]"]');
    setTimeout(() => {
      if(textarea) {
        (textarea as HTMLInputElement).focus();
      }
    }, 100);
  }

  async addWorkPackage() {
    this.titleInputTarget.classList.add("d-none");
    this.workPackageButtonTarget.classList.add("d-none");
    this.workPackageInputTarget.classList.remove("d-none");
    const select = this.element.querySelector('select[name="meeting_agenda_item[work_package_id]"]');
    setTimeout(() => {
      if(select) {
        (select as HTMLInputElement).focus();
      }
    }, 100);
  }
}

