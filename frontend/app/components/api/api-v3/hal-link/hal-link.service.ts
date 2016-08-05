//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {opApiModule} from '../../../../angular-modules';
import {HalRequestService} from '../hal-request/hal-request.service';
import {HalResource} from '../hal-resources/hal-resource.service';
import FunctionBind = _.FunctionBind;

var $q:ng.IQService;
var halRequest:HalRequestService;

export interface HalLinkInterface {
  href:string;
  method:string;
  title?:string;
  templated?:boolean;
  payload?:any;
}

interface CallableHalLink extends HalLinkInterface {
  (data?):ng.IPromise<HalResource>;
}

export class HalLink implements HalLinkInterface {
  /**
   * Create the HalLink from an object with the HalLinkInterface.
   */
  public static fromObject(link):HalLink {
    return new HalLink(link.href, link.title, link.method, link.templated, link.payload);
  }

  /**
   * Return a function that fetches the resource.
   */
  public static callable(link):CallableHalLink {
    return HalLink.fromObject(link).$callable();
  }

  constructor(public href:string = null,
              public title:string = '',
              public method:string = 'get',
              public templated:boolean = false,
              public payload?:any) {
  }

  /**
   * Fetch the resource.
   */
  public $fetch(...params):ng.IPromise<HalResource> {
    const [data, headers] = params;
    return halRequest.request(this.method, this.href, data, headers);
  }

  /**
   * Return a function that fetches the resource.
   *
   * @returns {CallableHalLink}
   */
  public $callable():CallableHalLink {
    const linkFunc:any = (...params) => this.$fetch(...params);

    _.extend(linkFunc, {
      $link: this,
      href: this.href,
      title: this.title,
      method: this.method,
      templated: this.templated,
      payload: this.payload
    });

    return linkFunc;
  }
}

function halLinkService(...args) {
  [$q, halRequest] = args;
  return HalLink;
}

halLinkService.$inject = ['$q', 'halRequest'];

opApiModule.factory('HalLink', halLinkService);
