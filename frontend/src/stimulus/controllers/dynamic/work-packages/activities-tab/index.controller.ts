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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';
import {
  ICKEditorInstance,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';

export default class IndexController extends Controller {
  static values = {
    updateStreamsUrl: String,
    sorting: String,
    pollingIntervalInMs: Number,
    filter: String,
  };

  static targets = ['journalsContainer', 'buttonRow', 'formRow', 'form'];

  declare readonly journalsContainerTarget:HTMLElement;
  declare readonly buttonRowTarget:HTMLInputElement;
  declare readonly formRowTarget:HTMLElement;
  declare readonly formTarget:HTMLFormElement;

  declare updateStreamsUrlValue:string;
  declare sortingValue:string;
  declare lastUpdateTimestamp:string;
  declare intervallId:number;
  declare pollingIntervalInMsValue:number;
  declare filterValue:string;

  connect() {
    this.setLastUpdateTimestamp();
    this.handleWorkPackageUpdate = this.handleWorkPackageUpdate.bind(this);
    document.addEventListener('work-package-updated', this.handleWorkPackageUpdate);

    if (window.location.hash.includes('#activity-')) {
      this.scrollToActivity();
    } else if (this.sortingValue === 'asc') {
      this.scrollToBottom();
    }

    this.intervallId = this.pollForUpdates();
  }

  disconnect() {
    document.removeEventListener('work-package-updated', this.handleWorkPackageUpdate);
    window.clearInterval(this.intervallId);
  }

  scrollToActivity() {
    const activityId = window.location.hash.replace('#activity-', '');
    const activityElement = document.getElementById(`activity-${activityId}`);
    if (activityElement) {
      activityElement.scrollIntoView({ behavior: 'smooth' });
    }
  }

  scrollToBottom():void {
    // copied from frontend/src/app/features/work-packages/components/work-package-comment/work-package-comment.component.ts
    const scrollableContainer = jQuery(this.element).scrollParent()[0];
    if (scrollableContainer) {
      setTimeout(() => {
        scrollableContainer.scrollTop = scrollableContainer.scrollHeight;
      }, 400);
    }
  }

  async handleWorkPackageUpdate(event:Event) {
    setTimeout(() => {
      this.updateActivitiesList();
    }, 2000); // TODO: wait dynamically for persisted change before updating the activities list
  }

  async updateActivitiesList() {
    const url = new URL(this.updateStreamsUrlValue);
    url.searchParams.append('last_update_timestamp', this.lastUpdateTimestamp);
    url.searchParams.append('filter', this.filterValue);

    const response = await fetch(
      url,
      {
        method: 'GET',
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      },
    );

    if (response.ok) {
      const text = await response.text();
      Turbo.renderStreamMessage(text);
      this.setLastUpdateTimestamp();
    }
  }

  pollForUpdates() {
    // protypical implementation of polling for updates in order to evaluate if we want to have this feature
    return window.setInterval(() => {
      this.updateActivitiesList();
    }, this.pollingIntervalInMsValue);
  }

  setFilterToOnlyComments() {
    this.filterValue = 'only_comments';
  }

  setFilterToOnlyChanges() {
    this.filterValue = 'only_changes';
  }

  unsetFilter() {
    this.filterValue = '';
  }

  getCkEditorElement() {
    return this.formRowTarget.querySelectorAll('.document-editor__editable')[0] as HTMLElement;
  }

  addEventListenerToCkEditorElement(ckEditorElement:HTMLElement) {
    ckEditorElement.addEventListener('keydown', (event) => {
      this.onCtrlEnter(event);
    });
    ckEditorElement.addEventListener('keyup', () => {
      this.adjustJournalContainerMargin();
    });
  }

  adjustJournalContainerMargin() {
    this.journalsContainerTarget.style.marginBottom = `${this.formRowTarget.clientHeight + 40}px`;
  }

  onCtrlEnter(event:KeyboardEvent) {
    if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
      this.onSubmit(event);
    }
  }

  scrollJournalContainerToBottom(journalsContainer:HTMLElement) {
    const scrollableContainer = jQuery(journalsContainer).scrollParent()[0];
    if (scrollableContainer) {
        scrollableContainer.scrollTop = scrollableContainer.scrollHeight;
    }
  }

  scrollJournalContainerToTop(journalsContainer:HTMLElement) {
    const scrollableContainer = jQuery(journalsContainer).scrollParent()[0];
    if (scrollableContainer) {
        scrollableContainer.scrollTop = 0;
    }
  }

  showForm() {
    this.buttonRowTarget.classList.add('d-none');
    this.formRowTarget.classList.remove('d-none');

    if (this.journalsContainerTarget) {
      this.journalsContainerTarget.classList.add('with-input-compensation');
    }

    const ckEditorElement = this.getCkEditorElement();
    if (ckEditorElement) {
      this.addEventListenerToCkEditorElement(ckEditorElement);

      setTimeout(() => {
        if (ckEditorElement) {
          ckEditorElement.focus();
        }
      }, 10);
    }
  }

  quote(event:Event) {
    event.preventDefault();
    const userName = (event.currentTarget as HTMLElement).dataset.userNameParam as string;
    const content = (event.currentTarget as HTMLElement).dataset.contentParam as string;

    this.openEditorWithQuotedText(this.quotedText(content, userName));
  }

  quotedText(rawComment:string, userName:string) {
    const quoted = rawComment.split('\n')
      .map((line:string) => `\n> ${line}`)
      .join('');

    return `${userName}\n${quoted}`;
  }

  openEditorWithQuotedText(quotedText:string) {
    this.showForm();
    const AngularCkEditorElement = this.element.querySelector('opce-ckeditor-augmented-textarea');
    if (AngularCkEditorElement) {
      const ckeditorInstance = jQuery(AngularCkEditorElement).data('editor') as ICKEditorInstance;
      if (ckeditorInstance) {
        const currentData = ckeditorInstance.getData({ trim: false });
        // only quote if the editor is empty
        if (currentData.length === 0) {
          ckeditorInstance.setData(quotedText);
        }
      }
    }
  }

  async onSubmit(event:Event) {
    event.preventDefault(); // Prevent the native form submission

    const form = this.formTarget;
    const formData = new FormData(form);
    formData.append('last_update_timestamp', this.lastUpdateTimestamp);
    formData.append('filter', this.filterValue);

    const action = form.action;

    const response = await fetch(
      action,
      {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      },
    );

    if (response.ok) {
      this.setLastUpdateTimestamp();
      const text = await response.text();
      Turbo.renderStreamMessage(text);

      if (this.journalsContainerTarget) {
        setTimeout(() => {
          this.journalsContainerTarget.style.marginBottom = '';
          this.journalsContainerTarget.classList.add('with-initial-input-compensation');
          this.journalsContainerTarget.classList.remove('with-input-compensation');
          if (this.sortingValue === 'asc') {
            this.scrollJournalContainerToBottom(this.journalsContainerTarget);
          } else {
            this.scrollJournalContainerToTop(this.journalsContainerTarget);
          }
        }, 100);
      }
    }
  }

  setLastUpdateTimestamp() {
    this.lastUpdateTimestamp = new Date().toISOString();
  }
}
