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

/**
 * API interfaces
 *
 * @see {@link http://opf.github.io/apiv3-doc/|Api V3 documentation}
 */

declare namespace api {

  /**
   * API v3
   */
  namespace v3 {
    interface Result {
      _links:any;
      _embedded:any;
      _type:string;
    }

    interface Collection extends Result {
      total:number;
      pageSize:number;
      count:number;
      offset:number;
      groups:any;
      totalSums:any;
    }

    interface Duration extends String {
    }

    interface Formattable {
      format:string;
      raw:string;
      html:string;
    }
  }
}

/**
 * OpenProject interfaces
 */

interface Function {
  $link?:any;
  name:string;
  _type:string;
}

declare var Factory:any;

declare namespace op {
  /**
   * General components
   */
  interface I18n {
    t(translateId:string, parameters?:any):string;
    lookup(translateId:string):boolean;
    locale:string;
  }

  interface CacheService {
    temporaryCache():any;
    localStorage():any;
    memoryStorage():any;
    customCache(identifier:any, params:any):any;
    isCacheDisabled():any;
    enableCaching():any;
    disableCaching():any;
    cachedPromise(promiseFn:any, key:any, options?:any):any;
  }

  interface FieldSchema {
    type:string;
    writable:boolean;
    allowedValues:any;
    required?:boolean;
    hasDefault:boolean;
    name?:string;
  }

  interface QueryParams {
    offset?:number;
    pageSize?:number;
    filters?:any[];
    groupBy?:string;
    showSums?:boolean;
    sortBy?:any[];
  }

  interface PathHelper {
    workPackagePath(id:any):string;
  }

  interface WorkPackagesHelper {
    formatValue(value:any, type:any):string;
  }
}
