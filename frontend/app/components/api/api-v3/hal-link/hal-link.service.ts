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

var $q:ng.IQService;
var apiV3:restangular.IService;

export default class HalLink {
  public static fromObject(link):HalLink {
    return new HalLink(link.href, link.title, link.method, link.templated);
  }

  public static asFunc(link) {
    return HalLink.fromObject(link).$toFunc();
  }

  constructor(public href:string,
              public title:string,
              public method:string,
              public templated:boolean) {

    this.href = href || null;
    this.title = title || '';
    this.method = method || 'get';
    this.templated = !!templated;
  }

  public $fetch(...params) {
    if (!this.href) {
      return $q.when({});
    }

    if (this.method === 'post') {
      params.unshift('');
    }

    return apiV3.oneUrl('route', this.href)[this.method](...params);
  }

  public $toFunc() {
    const func = (...params) => this.$fetch(...params);
    func.$link = this;

    return func;
  }
};

function halLink(_$q_:ng.IQService, _apiV3_:restangular.IService) {
  $q = _$q_;
  apiV3 = _apiV3_;

  return HalLink;
}

angular
  .module('openproject.api')
  .factory('HalLink', ['$q', 'apiV3', halLink]);
