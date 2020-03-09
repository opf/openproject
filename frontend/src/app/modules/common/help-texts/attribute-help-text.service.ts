// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {input} from 'reactivestates';
import {HelpTextResource} from 'core-app/modules/hal/resources/help-text-resource';
import {HelpTextDmService} from 'core-app/modules/hal/dm-services/help-text-dm.service';
import {Injectable} from '@angular/core';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';

@Injectable({ providedIn: 'root' })
export class AttributeHelpTextsService {
  private helpTexts = input<HelpTextResource[]>();

  constructor(private helpTextDm:HelpTextDmService) {
  }

  /**
   * Search for a given attribute help text
   *
   * @param attribute
   * @param scope
   */
  public require(attribute:string, scope:string):Promise<HelpTextResource|undefined> {
      this.helpTexts.putFromPromiseIfPristine(() =>
        this.helpTextDm
          .loadAll()
          .then((resources:CollectionResource<HelpTextResource>) => resources.elements)
      );

      return new Promise<HelpTextResource|undefined>((resolve, reject) => {
        this.helpTexts
          .valuesPromise()
          .then(() => resolve(this.find(attribute, scope)));
       });
  }

  private find(attribute:string, scope:string):HelpTextResource|undefined {
    const value = this.helpTexts.getValueOr([]);
    return _.find(value, (element) => element.scope === scope && element.attribute === attribute);
  }
}
