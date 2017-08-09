// -- copyright
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
// ++

import IAugmentedJQuery = angular.IAugmentedJQuery;
import {opUiComponentsModule} from '../../../angular-modules';
import {HelpTextResourceInterface} from '../../api/api-v3/hal-resources/help-text-resource.service';
import {HelpTextDmService} from '../../api/api-v3/hal-resource-dms/help-text-dm.service';
import {input} from 'reactivestates';
import {CollectionResourceInterface} from '../../api/api-v3/hal-resources/collection-resource.service';

export class AttributeHelpTextsService {
  private helpTexts = input<HelpTextResourceInterface[]>();

  constructor(private helpTextDm:HelpTextDmService,
              private $q:ng.IQService) {
  }

  /**
   * Search for a given attribute help text
   *
   * @param attribute
   * @param scope
   */
  public require(attribute:string, scope:string):ng.IPromise<HelpTextResourceInterface|undefined> {
    const deferred = this.$q.defer<HelpTextResourceInterface|undefined>();

    if (this.helpTexts.isPristine()) {
      this.helpTextDm.loadAll()
        .then((resources:CollectionResourceInterface) => {
          this.helpTexts.putValue(resources.elements as any);
          deferred.resolve(this.find(attribute, scope));
        });
    } else {
      deferred.resolve(this.find(attribute, scope));
    }

    return deferred.promise;
  }

  private find(attribute:string, scope:string):HelpTextResourceInterface|undefined {
    const value = this.helpTexts.getValueOr([]);
    return _.find(value, (element) => element.scope === scope && element.attribute === attribute);
  }
}

opUiComponentsModule.service('attributeHelpTexts', AttributeHelpTextsService);
