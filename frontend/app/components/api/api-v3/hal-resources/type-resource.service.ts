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
import {States} from "../../../states.service";
import {HalRequestService} from "../hal-request/hal-request.service";
import {CollectionResource} from "./collection-resource.service";
import {HalResource} from "./hal-resource.service";

var states: States;
var halRequest: HalRequestService;
var v3Path:any;

export class TypeResource extends HalResource {
  public color:string;

  public static loadAll():ng.IPromise<any> {
    const types = states.types;
    const typeUrl = v3Path.types();

    return halRequest.get(typeUrl).then((result:CollectionResource) => {
      result.elements.forEach((value:TypeResource) => {
        types.get(value.href as string).putValue(value);
      });
    });
  }

  public get state() {
    return states.types.get(this.href as string);
  }
}

function typeResource(...args:any[]) {
  [
    states,
    halRequest,
    v3Path
  ] = args;
  return TypeResource;
}

typeResource.$inject = [
  'states',
  'halRequest',
  'v3Path'
];

opApiModule.factory('TypeResource', typeResource);
