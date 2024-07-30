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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  HTTPClientHeaders,
  HTTPSupportedMethods,
} from 'core-app/features/hal/http/http.interfaces';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { firstValueFrom } from 'rxjs';

export interface HalLinkInterface {
  href:string|null;
  method:HTTPSupportedMethods;
  title?:string;
  templated?:boolean;
  payload?:any;
  type?:string;
  identifier?:string;
}

export interface HalLinkSource {
  href:string|null;
  title:string;
}

export interface CallableHalLink extends HalLinkInterface {
  $link:this;
  data?:Promise<HalResource>;
}

export class HalLink implements HalLinkInterface {
  constructor(public requestMethod:(method:HTTPSupportedMethods, href:string, data:any, headers:any) => Promise<HalResource>,
    public href:string|null = null,
    public title:string = '',
    public method:HTTPSupportedMethods = 'get',
    public templated:boolean = false,
    public payload?:any,
    public type:string = 'application/json',
    public identifier?:string) {
  }

  /**
   * Create the HalLink from an object with the HalLinkInterface.
   */
  public static fromObject(halResourceService:HalResourceService, link:HalLinkInterface):HalLink {
    return new HalLink(
      (method:HTTPSupportedMethods, href:string, data:object, headers:HTTPClientHeaders) => firstValueFrom(halResourceService.request(method, href, data, headers)),
      link.href,
      link.title,
      link.method,
      link.templated,
      link.payload,
      link.type,
      link.identifier,
    );
  }

  /**
   * Fetch the resource.
   */
  public $fetch(...params:any[]):Promise<HalResource> {
    const [data, headers] = params;
    return this.requestMethod(this.method, this.href as string, data, headers);
  }

  /**
   * Prepare the templated link and return a CallableHalLink with the templated parameters set
   *
   * @returns {CallableHalLink}
   */
  public $prepare(templateValues:{ [templateKey:string]:string }) {
    if (!this.templated) {
      throw new Error(`The link ${this.href} is not templated.`);
    }

    let href = _.clone(this.href) || '';
    _.each(templateValues, (value:string, key:string) => {
      const regexp = new RegExp(`{${key}}`);
      href = href.replace(regexp, value);
    });

    return new HalLink(
      this.requestMethod,
      href,
      this.title,
      this.method,
      false,
      this.payload,
      this.type,
      this.identifier,
    ).$callable();
  }

  /**
   * Return a function that fetches the resource.
   *
   * @returns {CallableHalLink}
   */
  public $callable():CallableHalLink {
    const linkFunc:any = (...params:any[]) => this.$fetch(...params);

    _.extend(linkFunc, {
      $link: this,
      href: this.href,
      title: this.title,
      method: this.method,
      templated: this.templated,
      payload: this.payload,
      type: this.type,
      identifier: this.identifier,
    });

    return linkFunc;
  }
}
