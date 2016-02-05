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
 * API V3 Interfaces
 *
 * @see {@link http://opf.github.io/apiv3-doc/|Api V3 documentation}
 */

declare var Api;

declare namespace Api {
  interface Collection {
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
 * OpenProject interfaces
 *
 */

declare var op;

declare namespace op {
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
    t(translateId:string):string;
  }

  /**
   * OpenProject API results - restangular
   *
   */

  interface WorkPacakge extends Api.WorkPackage, restangular.IResponse {

  }
}
