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

import {opApiModule} from "../../../../angular-modules";

var $q:ng.IQService;
var apiV3:restangular.IService;

export interface HalLinkInterface {
  href:string;
  method:string;
  title?:string;
  templated?:boolean;
}

export class HalLink implements HalLinkInterface {
  public static fromObject(link):HalLink {
    return new HalLink(link.href, link.title, link.method, link.templated);
  }

  public static asFunc(link) {
    return HalLink.fromObject(link).$toFunc();
  }

  /**
   *  Return the restangular element.
   */
  public get $route():restangular.IElement {
    return apiV3.oneUrl('route', this.href);
  }

  constructor(public href:string = null,
              public title:string = '',
              public method:string = 'get',
              public templated:boolean = false) {
  }

  public $fetch(...params) {
    if (!this.href) {
      return $q.when({});
    }

    if (this.method === 'post') {
      params.unshift('');
    }

    return this.$route[this.method === 'delete' && 'remove' || this.method](...params);
  }

  public $toFunc() {
    const func:any = (...params) => this.$fetch(...params);
    func.$link = this;
    func.$route = this.$route;

    return func;
  }
}

function halLinkService(...args) {
  [$q, apiV3] = args;
  return HalLink;
}

halLinkService.$inject = ['$q', 'apiV3'];

opApiModule.factory('HalLink', halLinkService);
