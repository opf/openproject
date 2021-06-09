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

import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";

export const indicatorLocationSelector = '.loading-indicator--location';
export const indicatorBackgroundSelector = '.loading-indicator--background';

export function withLoadingIndicator<T>(indicator:LoadingIndicator, delayStopTime?:number):(source:Observable<T>) => Observable<T> {
  return (source$:Observable<T>) => {
    indicator.start();

    return source$.pipe(
      tap(
        () => indicator.delayedStop(delayStopTime),
        () => indicator.stop(),
        () => indicator.stop()
      )
    );
  };
}

export function withDelayedLoadingIndicator<T>(indicator:() => LoadingIndicator):(source:Observable<T>) => Observable<T> {
  return (source$:Observable<T>) => {
    setTimeout(() => indicator().start());

    return source$.pipe(
      tap(
        () => undefined,
        () => indicator().stop(),
        () => indicator().stop()
      )
    );
  };
}


export class LoadingIndicator {

  private indicatorTemplate =
    `<div class="loading-indicator--background">
      <div class="loading-indicator">
        <div class="block-1"></div>
        <div class="block-2"></div>
        <div class="block-3"></div>
        <div class="block-4"></div>
        <div class="block-5"></div>
      </div>
    </div>
   `;

  constructor(public indicator:JQuery) {
  }

  public set promise(promise:Promise<unknown>) {
    this.start();

    // Keep bound method around
    const stopper = () => this.delayedStop();

    promise
      .then(stopper)
      .catch(stopper);
  }

  public start() {
    // If we're currently having an active indicator, remove that one
    this.stop();
    this.indicator.prepend(this.indicatorTemplate);
  }

  public delayedStop(time = 25) {
    setTimeout(() => this.stop(), time);
  }

  public stop() {
    this.indicator.find('.loading-indicator--background').remove();
  }
}

@Injectable({ providedIn: 'root' })
export class LoadingIndicatorService {

  // Provide shortcut to the primarily used indicators
  public get table() {
    return this.indicator('table');
  }

  public get wpDetails() {
    return this.indicator('wpDetails');
  }

  public get modal() {
    return this.indicator('modal');
  }

  // Returns a getter function to an indicator
  // in case the indicator is shown conditionally
  public getter(name:string):() => LoadingIndicator {
    return this.indicator.bind(this, name);
  }

  // Return an indicator by name or element
  public indicator(indicator:string|JQuery):LoadingIndicator {
    if (typeof indicator === 'string') {
      indicator = this.getIndicatorAt(indicator) as JQuery;
    }

    return new LoadingIndicator(indicator);
  }

  private getIndicatorAt(name:string):JQuery {
    return jQuery(indicatorLocationSelector).filter(`[data-indicator-name="${name}"]`);
  }
}
