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
// ++

import {ApplicationRef, ComponentFactoryResolver, ComponentRef, Injectable, Injector} from "@angular/core";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Injectable()
export class CKEditorPreviewService {

  constructor(private readonly componentFactoryResolver:ComponentFactoryResolver,
              private readonly appRef:ApplicationRef,
              private readonly injector:Injector) {
  }

  /**
   * Render preview into the given element, return a remover function to disconnect all
   * dynamic components (if any).
   *
   * @param {HTMLElement} hostElement
   * @param {string} preview
   * @returns {() => void}
   */
  public render(hostElement:HTMLElement, preview:string):() => void {
    hostElement.innerHTML = preview;
    let refs:ComponentRef<any>[] = [];

    DynamicBootstrapper
      .getEmbeddable()
      .forEach((entry) => {
      const matchedElements = hostElement.querySelectorAll(entry.selector);

      for (let i = 0, l = matchedElements.length; i < l; i++) {
        const factory = this.componentFactoryResolver.resolveComponentFactory(entry.cls);
        const componentRef = factory.create(this.injector, [], matchedElements[i]);

        refs.push(componentRef);
        this.appRef.attachView(componentRef.hostView);
        componentRef.changeDetectorRef.detectChanges();
      }
    });

    return () => {
      refs.forEach(ref => {
        this.appRef.detachView(ref.hostView);
        ref.destroy();
      });
      refs.length = 0;
      hostElement.innerHTML = '';
    };
  }
}
