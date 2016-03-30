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
declare var api;

declare namespace api {

  /**
   * API v3
   */
  namespace v3 {
    interface Result {
      _links;
      _embedded;
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

    interface WorkPackage {
      id:number;
      lockVersion:number;
      subject:string;
      type:string;
      description:Formattable;
      parentId:number;
      startDate:Date;
      dueDate:Date;
      estimatedTime:Duration;
      spentTime:Duration;
      percentageDone:number;
      createdAt:Date;
      updatedAt:Date;
    }

    interface Project {

    }

    interface Query {

    }
  }

  /**
   * Experimental API
   */
  namespace ex {
    interface ColumnMeta {
      data_type:string;
      link:{
        display:boolean;
        model_type:string;
      };
    }

    interface Column {
      name:string;
      title:string;
      custom_field:boolean;
      sortable:boolean;
      goupable:boolean;
      meta_data:ColumnMeta;
    }

    interface Query {
      _links:any;
      id:number;
      columnNames;
      displaySums:boolean;
      filters;
      groupBy:string;
      isPublic:boolean;
      name:string;
      projectId:number;
      sortCriteria;
      starred:boolean;
      userId:number;
    }

    interface Meta {
      _links;
      columns:Column[];
      export_formats;
      group_sums;
      groupable_columns:Column[];
      per_page_options:number[];
      query:Query;
      sums:any[]; // TODO: Add correct type
      total_entries:number;
      work_package_count_by_group;
      page:number;
      per_page:number;
    }

    interface WorkPackagesMeta {
      meta:Meta;
      work_packages;
    }
  }
}

/**
 * OpenProject interfaces
 */

interface Function {
  $link?:op.HalLink;
}

declare namespace op {
  /**
   * General components
   */
  interface Query {
    id?:number;
    columns?:any;
    displaySums?;
    projectId?;
    groupBy?:string;
    filters?;
    sortCriteria?;
    page?:number;
    perPage?:number;

    toUpdateParams?():any;
  }

  interface I18n {
    t(translateId:string, parameters?:any):string;
  }

  interface CacheService {
    temporaryCache();
    localStorage();
    memoryStorage();
    customCache(identifier, params);
    isCacheDisabled();
    enableCaching();
    disableCaching();
    cachedPromise(promiseFn, key, options?);
    loadResource(resource, force);
  }

  /**
   * OpenProject API results with Restangular
   */
  interface ApiResult extends api.v3.Result, restangular.IElement {
    restangularized:boolean;
  }

  class HalResource {
    public $links;
    public $embedded;
    public $isHal;
    public name:string;
    public href:string;

    constructor($source:restangular.IElement);

    public $plain();
  }

  class HalLink {
    public href:string;
    public title:string;
    public method:string;
    public templated:boolean;
  }

  interface FieldSchema {
    type:string;
    writable:boolean;
    allowedValues;
  }

  interface WorkPackageLinks {
    schema:FieldSchema;
  }

  interface WorkPackage extends api.v3.WorkPackage, WorkPackageLinks {

    getForm();
    getSchema();

    update();
    links: WorkPackageLinks
  }

  interface QueryParams {
    offset?:number;
    pageSize?:number;
    filters?:any[];
    groupBy?:string;
    showSums?:boolean;
    sortBy?:any[];
  }
}
