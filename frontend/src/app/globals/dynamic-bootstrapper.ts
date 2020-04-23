// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {ComponentType} from "@angular/cdk/portal";
import {ApplicationRef} from "@angular/core";

/**
 * Optional bootstrap definition to allow selecting all matching
 * DOM nodes to manually bootstrap them.
 *
 * This differs from Angular's bootstrap module definition since it expects these
 * entries to be present on ALL pages. This is never the case for our optional
 * bootstrapped components.
 */
export interface OptionalBootstrapDefinition {
  // The DOM selector used to locate an optional node
  selector:string;
  // The component class tied to it.
  cls:ComponentType<any>;
  // Whether the component may be embeddable in dynamically generated responses
  // e.g., previews
  embeddable?:boolean;
}

/**
 * Static lookup table for dynamically bootstrapped components within our application
 */
export class DynamicBootstrapper {
  private static optionalBoostrapComponents:OptionalBootstrapDefinition[] = [];

  /**
   * Register an optional bootstrap component to be dynamically bootstrapped
   * whenever it occurs in the initially loaded DOM.
   *
   * @param {OptionalBootstrapDefinition} definition
   */
  public static register(...defs:OptionalBootstrapDefinition[]) {
    this.optionalBoostrapComponents.push(...defs);
  }

  /**
   * Perform bootstrapping of matched elements within the given document.
   *
   * @param {ApplicationRef} appRef The application reference to lookup elements.
   * @param {Document} doc The document element
   * @param {OptionalBootstrapDefinition[]|undefined} definitions An optional set of components to bootstrap
   */
  public static bootstrapOptionalDocument(appRef:ApplicationRef, doc:Document, definitions = this.optionalBoostrapComponents) {
    this.performBootstrap(appRef, doc, false, definitions);
  }

  /**
   * Perform bootstrapping of embeddable elements within the given node.
   *
   * @param {ApplicationRef} appRef The application reference to lookup elements.
   * @param {HTMLElement} element A node to bootstrap elements within.
   * @param {OptionalBootstrapDefinition[]|undefined} definitions An optional set of components to bootstrap
   */
  public static bootstrapOptionalEmbeddable(appRef:ApplicationRef, element:HTMLElement, definitions = this.optionalBoostrapComponents) {
    this.performBootstrap(appRef, element, true, definitions);
  }

  /**
   * Get embeddable components
   */
  public static getEmbeddable() {
    return this.optionalBoostrapComponents.filter(el => el.embeddable);
  }

  /**
   * Bootstrap within a given document (globally, all components available) or within an element (embeddable compoennts
   * only).
   *
   * @param {ApplicationRef} appRef
   * @param {Document | HTMLElement} root
   * @param {boolean} embedded
   */
  private static performBootstrap(appRef:ApplicationRef, root:Document|HTMLElement, embedded:boolean, definitions:OptionalBootstrapDefinition[]) {
    definitions
      .forEach(el => {

        // Skip non-embeddable components in an embedded bootstrap.
        if (embedded && !el.embeddable) {
          return;
        }

        const elements = root.querySelectorAll(el.selector);
        for (let i = 0; i < elements.length; i++) {
          appRef.bootstrap(el.cls, elements[i]);
        }
      });
  }
}
