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

import { Injectable, DOCUMENT, inject } from '@angular/core';
import { enterpriseEditionUrl } from 'core-app/core/setup/globals/constants.const';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Injectable({ providedIn: 'root' })
export class BannersService {
  protected documentElement = inject<Document>(DOCUMENT);
  protected configuration = inject(ConfigurationService);

  private readonly _bannersHidden:boolean = true;

  constructor() {
    const documentElement = this.documentElement;

    this._bannersHidden = documentElement.body.classList.contains('ee-banners-hidden');
  }

  public showBannerFor(feature:string):boolean {
    if (this._bannersHidden) {
      return false;
    }

    return !this.allowsTo(feature) || this.trialling(feature);
  }

  public allowsTo(feature:string):boolean {
    return this.configuration.availableFeatures.includes(feature);
  }

  public trialling(feature:string):boolean {
    return this.configuration.triallingFeatures.includes(feature);
  }

  public getEnterPriseEditionUrl({ referrer, hash }:{ referrer?:string, hash?:string } = {}) {
    const url = new URL(enterpriseEditionUrl);
    if (referrer) {
      url.searchParams.set('op_referrer', referrer);
    }

    if (hash) {
      url.hash = hash;
    }

    return url.toString();
  }

  public async conditional(feature:string, featureNotAvailable?:() => void, featureAvailable?:() => void) {
    await this.configuration.initialize();

    if (this.allowsTo(feature)) {
      this.callMaybe(featureAvailable);
    } else {
      this.callMaybe(featureNotAvailable);
    }
  }

  private callMaybe(func?:() => unknown) {
    func?.();
  }
}
