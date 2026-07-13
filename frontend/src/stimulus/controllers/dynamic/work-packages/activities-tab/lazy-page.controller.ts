/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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

import { useIntersection } from 'stimulus-use';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import BaseController from './base.controller';

export default class LazyPageController extends BaseController {
  static services:ServiceKey[] = ['turboRequests'];

  static values = {
    url: String,
    page: { type: Number, default: 1 },
    isLoaded: { type: Boolean, default: false },
    loadDelayMs: { type: Number, default: 300 },
  };

  declare urlValue:string;
  declare pageValue:number;
  declare isLoadedValue:boolean;
  declare loadDelayMsValue:number;

  declare services:Promise<PickedServices<'turboRequests'>>;

  private stopObserving?:() => void;
  private loadTimeout?:number;

  initialize() {
    super.initialize();
    useAngularServices(this);
  }

  connect() {
    if (this.isLoadedValue) return;

    super.connect();
    this.startObserving();
  }

  disconnect() {
    super.disconnect();
    this.cancelPendingLoad();
    this.stopObserving?.();
  }

  appear() {
    if (this.isLoadedValue) return;

    // Delay loading to allow rapid scrolling without triggering loads
    this.loadTimeout = window.setTimeout(() => {
      void this.fetchPageStream()
        .catch((error) => {
          console.error('Error fetching next page:', error);
        }).finally(() => {
          this.isLoadedValue = true;
        });
    }, this.loadDelayMsValue);
  }

  disappear() {
    this.cancelPendingLoad(); // Cancel load if element leaves viewport before delay expires
  }

  private startObserving() {
    const [_observe, unobserve] = useIntersection(this, {
      root: null, // Use document viewport as root to prevent false - positive intersections during responsive layout shifts
      threshold: 0.05,
      dispatchEvent: false
    });

    this.stopObserving = unobserve;
  }

  private async fetchPageStream():Promise<{ html:string, headers:Headers }> {
    const url = this.preparePageStreamsUrl();
    const { turboRequests } = await this.services;
    return turboRequests.requestStream(url);
  }

  private preparePageStreamsUrl():string {
    const baseUrl = window.location.origin;
    const url = new URL(this.urlValue, baseUrl);

    url.searchParams.set('page', this.pageValue.toString());
    url.searchParams.set('filter', this.indexOutlet.filterValue);

    return url.toString();
  }

  private cancelPendingLoad() {
    if (this.loadTimeout) {
      window.clearTimeout(this.loadTimeout);
      this.loadTimeout = undefined;
    }
  }
}
