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

export default class NewController extends Controller {
  static values = {
    sorting: String,
  };

  static targets = ['buttonRow', 'formRow', 'form'];

  declare readonly buttonRowTarget:HTMLInputElement;
  declare readonly formRowTarget:HTMLInputElement;
  declare readonly formTarget:HTMLFormElement;

  declare sortingValue:string;

  getCkEditorElement() {
    return this.formRowTarget.querySelectorAll('.document-editor__editable')[0] as HTMLElement;
  }

  addEventListenerToCkEditorElement(ckEditorElement:HTMLElement) {
    ckEditorElement.addEventListener('keydown', (event) => {
      this.onCtrlEnter(event);
    });
  }

  onCtrlEnter(event:KeyboardEvent) {
    if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
      this.onSubmit(event);
    }
  }

  getJournalsContainer() {
    return document.querySelector('#work-packages-activities-tab-index-component #journals-container') as HTMLElement;
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

    const journalsContainer = this.getJournalsContainer();
    if (journalsContainer) {
      journalsContainer.classList.add('with-input-compensation');
      if (this.sortingValue === 'asc') {
        this.scrollJournalContainerToBottom(journalsContainer);
      } else {
        // this.scrollJournalContainerToTop(journalsContainer);
      }
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

  async onSubmit(event:Event) {
    event.preventDefault(); // Prevent the native form submission

    const form = this.formTarget;
    const formData = new FormData(form);
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
      const text = await response.text();
      Turbo.renderStreamMessage(text);

      const journalsContainer = this.getJournalsContainer();
      if (journalsContainer) {
        setTimeout(() => {
          journalsContainer.classList.remove('with-input-compensation');
          if (this.sortingValue === 'asc') {
            this.scrollJournalContainerToBottom(journalsContainer);
          } else {
            this.scrollJournalContainerToTop(journalsContainer);
          }
        }, 100);
      }
    }
  }
}
