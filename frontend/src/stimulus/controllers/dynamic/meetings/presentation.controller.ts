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

export default class PresentationController extends Controller {
  static targets = [
    'previousButton',
    'nextButton',
  ];

  previousButtonTarget:HTMLButtonElement;
  nextButtonTarget:HTMLButtonElement;

  private abortController = new AbortController();
  private openFieldsSelector = 'input, textarea, op-ckeditor, [contenteditable]';

  connect() {
    const { signal } = this.abortController;
    window.addEventListener('keydown', this, { signal });
  }

  handleEvent(event:KeyboardEvent) {
    // Ignore key events when user is actively editing
    if (window.OpenProject.pageState === 'edited') {
      return;
    }

    // Ignore key events when focus is on an input, textarea, or contenteditable element
    if ((event.target as HTMLElement).closest(this.openFieldsSelector)) {
      return;
    }

    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        this.previous();
        break;
      case 'ArrowRight':
      case ' ': // Spacebar
        event.preventDefault();
        this.next();
        break;
    }
  }

  disconnect() {
    this.abortController.abort();
  }

  previous() {
    if (!this.previousButtonTarget.disabled) {
      this.previousButtonTarget.click();
    }
  }

  next() {
    if (!this.nextButtonTarget.disabled) {
      this.nextButtonTarget.click();
    }
  }
}
