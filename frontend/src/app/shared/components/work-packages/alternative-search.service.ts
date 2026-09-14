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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';

@Injectable({ providedIn: 'root' })
export class AlternativeSearchService {
  readonly I18n = inject(I18nService);


  private specialSearchStrings = {
    percentComplete: this.I18n.t('js.work_packages.properties.percentComplete'),
    percentCompleteAlternative: this.I18n.t('js.work_packages.properties.percentCompleteAlternative'),
    work: this.I18n.t('js.work_packages.properties.work'),
    workAlternative: this.I18n.t('js.work_packages.properties.workAlternative'),
    remainingWork: this.I18n.t('js.work_packages.properties.remainingWork'),
    remainingWorkAlternative: this.I18n.t('js.work_packages.properties.remainingWorkAlternative'),
  };

  private alternativeNames:Record<string, string> = {
    [this.specialSearchStrings.percentCompleteAlternative]: this.specialSearchStrings.percentComplete,
    [this.specialSearchStrings.workAlternative]: this.specialSearchStrings.work,
    [this.specialSearchStrings.remainingWorkAlternative]: this.specialSearchStrings.remainingWork,
  };

  public searchFunction = (term:string, currentItem:QueryFilterResource):boolean => {
    const lowercaseSearchTerm = term.toLowerCase();
    const lowercaseCurrentItemName = currentItem.name.toLowerCase();

    const alternativeMatch = Object
      .keys(this.alternativeNames)
      .some((alternativeName) => {
        return alternativeName.toLowerCase().includes(lowercaseSearchTerm)
          && currentItem.name === this.alternativeNames[alternativeName];
      });

    return lowercaseCurrentItemName.includes(lowercaseSearchTerm)
      || alternativeMatch;
  };
}
