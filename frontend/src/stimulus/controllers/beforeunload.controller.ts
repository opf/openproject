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

import { ApplicationController } from 'stimulus-use';
import { TurboBeforeVisitEvent } from '@hotwired/turbo';

export class BeforeunloadController extends ApplicationController {
  private abortController = new AbortController();

  connect() {
    super.connect();

    const { signal } = this.abortController;

    window.addEventListener('beforeunload', this, { signal });
    document.addEventListener('turbo:before-visit', this, { signal });
    document.addEventListener('turbo:submit-end', this, { signal });
    document.addEventListener('turbo:load', this, { signal });
    document.addEventListener('turbo:render', this, { signal });
    document.addEventListener('submit', this, { signal });
  }

  disconnect() {
    this.abortController.abort();
  }

  handleEvent(evt:Event) {
    switch (evt.type) {
      case 'beforeunload':
      case 'turbo:before-visit':
        this.beforeunloadHandler(evt);
        break;
      case 'turbo:submit-end':
      case 'turbo:load':
      case 'turbo:render':
        window.OpenProject.pageState = 'pristine';
        break;
      case 'submit':
        window.OpenProject.pageState = 'submitted';
        break;
      default:
        break;
    }
  }

  private beforeunloadHandler(evt:BeforeUnloadEvent|TurboBeforeVisitEvent) {
    const hasUnsavedChanges = evt.type === 'turbo:before-visit'
      ? window.OpenProject.pageHasUnsavedChanges
      : window.OpenProject.pageWasEdited;

    if (!hasUnsavedChanges) {
      return;
    }

    if (window.confirm(I18n.t('js.text_are_you_sure_to_cancel'))) {
      return;
    }

    // Cancel the event
    evt.preventDefault();

    // Chrome requires returnValue to be set
    if (evt.type === 'beforeunload') {
      evt.returnValue = '';
    }
  }
}
