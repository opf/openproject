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

import {wpDirectivesModule} from '../../../../angular-modules';
import {HalRequestService} from '../hal-request/hal-request.service';
import {CollectionResource} from '../hal-resources/collection-resource.service';
import {RelationResource} from '../hal-resources/relation-resource.service';
import {buildApiV3Filter} from '../api-v3-filter-builder';

export class RelationsDmService {

  constructor(private halRequest:HalRequestService,
              private v3Path:any,
              private $q:ng.IQService) {

  }

  public load(workPackageId:string):ng.IPromise<RelationResource[]> {
    return this.halRequest.get(
      this.v3Path.wp.relations({wp: workPackageId}),
      {},
      {
        caching: {enabled: false}
      }).then((collection:CollectionResource) => {
        return collection.elements;
    });
  }

  public loadInvolved(workPackageIds:string[]):ng.IPromise<RelationResource[]> {
    let validIds = _.filter(workPackageIds, id => /\d+/.test(id));

    if (validIds.length === 0) {
      return this.$q.resolve([]);
    }

    return this.halRequest.get(
      '/api/v3/relations',
      {
        filters: buildApiV3Filter('involved', '=', validIds).toJson()
      },
      {
        caching: {enabled: false}
      }).then((collection:CollectionResource) => {
      return collection.elements;
    });
  }
}

wpDirectivesModule.service('relationsDm', RelationsDmService);
