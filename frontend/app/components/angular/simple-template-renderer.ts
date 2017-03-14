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

import {opServicesModule} from '../../angular-modules';

export class SimpleTemplateRenderer {

  constructor(public $compile:ng.ICompileService,
              public $templateCache:ng.ITemplateCacheService,
              public $q:ng.IQService,
              public $timeout:ng.ITimeoutService,
              public $rootScope:ng.IRootScopeService) {
  }

  /**
   * Render the given angular template in an isolated scope
   * into the given element.
   *
   * All content of the element is replaced.
   */
  public renderIsolated(element:HTMLElement,
                        template:string,
                        scopeValues:Object):ng.IPromise<ng.IAugmentedJQuery> {
    const scope = this.$rootScope.$new();
    const deferred = this.$q.defer();
    _.assign(scope, scopeValues);

    const templateEl = angular.element(this.$templateCache.get(template) as string);
    this.$compile(templateEl)(scope, (clonedElement:ng.IAugmentedJQuery, scope) => {
      element.innerHTML = '';
      element.appendChild(clonedElement[0]);

      this.$timeout(() => deferred.resolve(clonedElement));
    });

    return deferred.promise;
  }
}

SimpleTemplateRenderer.$inject = ['$compile', '$templateCache', '$q', '$timeout', '$rootScope'];
opServicesModule.service('templateRenderer', SimpleTemplateRenderer);
