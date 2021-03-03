//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++


import { Inject, Injectable, Injector } from "@angular/core";
import { DOCUMENT } from "@angular/common";
import { DynamicContentModal } from "core-components/modals/modal-wrapper/dynamic-content.modal";
import { OpModalService } from "core-app/modules/modal/modal.service";

const iframeSelector = '.iframe-target-wrapper';

/**
 * This service takes modals that are rendered by the rails backend,
 * and re-renders them with the angular op-modal service
 */
@Injectable({ providedIn: 'root' })
export class OpModalWrapperAugmentService {

  constructor(@Inject(DOCUMENT) protected documentElement:Document,
              protected injector:Injector,
              protected opModalService:OpModalService) {
  }

  /**
   * Create initial listeners for Rails-rendered modals
   */
  public setupListener() {
    const matches = this.documentElement.querySelectorAll('section[data-augmented-model-wrapper]');
    for (let i = 0; i < matches.length; ++i) {
      this.wrapElement(jQuery(matches[i]) as JQuery);
    }
  }

  /**
   * Wrap a section[data-augmented-modal-wrapper] element
   */
  public wrapElement(element:JQuery) {
    // Find activation link
    const activationSelector = element.data('activationSelector') || '.modal-delivery-element--activation-link';
    const activationLink = jQuery(activationSelector);

    const initializeNow = element.data('modalInitializeNow');

    if (initializeNow) {
      this.show(element);
    } else {
      activationLink.click((evt:JQuery.TriggeredEvent) => {
        this.show(element);
        evt.preventDefault();
      });
    }
  }

  private show(element:JQuery) {
    // Set modal class name
    const modalClassName = element.data('modalClassName');
    // Append CSP-whitelisted IFrame for onboarding
    const iframeUrl = element.data('modalIframeUrl');

    // Set template from wrapped element
    const wrappedElement = element.find('.modal-delivery-element');
    let modalBody = wrappedElement.html();

    if (iframeUrl) {
      modalBody = this.appendIframe(modalBody, iframeUrl);
    }

    this.opModalService.show(
      DynamicContentModal,
      this.injector,
      {
        modalBody: modalBody,
        modalClassName: modalClassName
      }
    );
  }

  private appendIframe(body:string, url:string) {
    const subdom = jQuery(body);
    const iframe = jQuery('<iframe frameborder="0" height="400" allowfullscreen>></iframe>');
    iframe.attr('src', url);

    subdom.find(iframeSelector).append(iframe);

    return subdom.html();
  }
}
