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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector, DOCUMENT, inject } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { DynamicContentModalComponent } from 'core-app/shared/components/modals/modal-wrapper/dynamic-content.modal';

/**
 * This service takes modals that are rendered by the rails backend,
 * and re-renders them with the angular op-modal service
 */
@Injectable({ providedIn: 'root' })
export class OpModalWrapperAugmentService {
  protected documentElement = inject<Document>(DOCUMENT);
  protected injector = inject(Injector);
  protected opModalService = inject(OpModalService);

  constructor() {
    const documentElement = this.documentElement;
    const opModalService = this.opModalService;

    documentElement.addEventListener('turbo:before-render', () => opModalService.close());
  }

  /**
   * Create initial listeners for Rails-rendered modals
   */
  public setupListener() {
    const matches = this.documentElement.querySelectorAll('[data-augmented-model-wrapper]');
    for (let i = 0; i < matches.length; ++i) {
      this.wrapElement(matches[i] as HTMLElement);
    }
  }

  /**
   * Wrap a section[data-augmented-modal-wrapper] element
   */
  public wrapElement(element:HTMLElement) {
    // Find activation link
    const activationSelector = element.dataset.activationSelector || '.modal-delivery-element--activation-link';
    const activationLink = document.querySelector(activationSelector);
    const initializeNow = element.dataset.modalInitializeNow;

    if (initializeNow) {
      this.show(element);
    } else {
      activationLink?.addEventListener('click', (evt) => {
        this.show(element);
        evt.preventDefault();
      });
    }
  }

  private show(element:HTMLElement) {
    // Set modal class name
    const modalClassName = element.dataset.modalClassName;

    // Set template from wrapped element
    const wrappedElement = element.querySelector<HTMLElement>('.modal-delivery-element')!;
    const modalBody = wrappedElement.innerHTML;

    this.opModalService.show(
      DynamicContentModalComponent,
      this.injector,
      {
        modalBody,
        modalClassName,
      },
    );
  }
}
