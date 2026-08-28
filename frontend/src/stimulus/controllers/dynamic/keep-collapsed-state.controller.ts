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
import type { CollapsibleElement } from '@openproject/primer-view-components/app/components/primer/open_project/collapsible';
import { useMutation } from 'stimulus-use';

const COLLAPSED_ATTRIBUTE = 'data-collapsed';
const COLLAPSIBLE_SELECTOR = 'collapsible-header, collapsible-section';
const TOGGLE_SELECTOR = '[data-collapsible-toggle]';

const isCollapsible = (node:Node):node is CollapsibleElement => node instanceof Element
  && node.matches(COLLAPSIBLE_SELECTOR);

// Carries the collapsed state of Primer collapsibles over turbo frame and
// turbo stream renders, which would otherwise reset them to the state the
// server rendered.
//
// Mount on a stable ancestor, never inside the content that gets replaced:
// that element's lifetime is the remembered state's lifetime, so removing it
// is what returns the collapsibles to their default. State is keyed on the
// `aria-controls` of each toggle, so a collapsible left with a generated id
// is not kept across renders.
export default class KeepCollapsedStateController extends Controller<HTMLElement> {
  private collapsedByKey = new Map<string, boolean>();

  connect():void {
    useMutation(this, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: [COLLAPSED_ATTRIBUTE],
      dispatchEvent: false,
    });
  }

  disconnect():void {
    this.collapsedByKey.clear();
  }

  mutate(mutations:MutationRecord[]):void {
    mutations.forEach(({ type, target, addedNodes }) => {
      if (type === 'attributes') {
        if (isCollapsible(target)) {
          this.remember(target);
        }
      } else {
        addedNodes.forEach((node) => this.eachCollapsibleIn(node, (el) => this.restore(el)));
      }
    });
  }

  private remember(collapsible:CollapsibleElement):void {
    const key = this.keyOf(collapsible);

    if (key) {
      this.collapsedByKey.set(key, collapsible.collapsed);
    }
  }

  private restore(collapsible:CollapsibleElement):void {
    const key = this.keyOf(collapsible);
    const collapsed = key ? this.collapsedByKey.get(key) : undefined;

    if (collapsed !== undefined && collapsed !== collapsible.collapsed) {
      collapsible.toggle();
    }
  }

  private eachCollapsibleIn(node:Node, callback:(collapsible:CollapsibleElement) => void):void {
    if (!(node instanceof Element)) {
      return;
    }

    if (isCollapsible(node)) {
      callback(node);
    }

    node.querySelectorAll<CollapsibleElement>(COLLAPSIBLE_SELECTOR).forEach(callback);
  }

  private keyOf(collapsible:CollapsibleElement):string|undefined {
    return collapsible.querySelector(TOGGLE_SELECTOR)?.getAttribute('aria-controls') ?? undefined;
  }
}
