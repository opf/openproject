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
      format?:string;
      raw:string;
      html?:string;
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

interface JQuery {
  topShelf:any;
  mark:any;
}

declare let Factory:any;

declare namespace op {
  interface QueryParams {
    offset?:number;
    pageSize?:number;
    filters?:any[];
    groupBy?:string;
    showSums?:boolean;
    sortBy?:any[];
  }
}
