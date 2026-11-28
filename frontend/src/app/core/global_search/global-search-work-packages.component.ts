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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectorRef,
  Component,
  inject,
  input,
  OnDestroy,
  OnInit,
  Renderer2,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import {
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { QueryRequestParams } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { booleanAttributeOr, stringAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

const SEARCH_SCOPES = ['all', 'current_project', ''] as const;
type SearchScope = typeof SEARCH_SCOPES[number];
type SearchMode = 'semantic'|'text';

function isSearchScope(value:unknown):value is SearchScope {
  return SEARCH_SCOPES.includes(value as SearchScope);
}

@Component({
  selector: 'opce-global-search-work-packages',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: `
    <wp-embedded-table [queryProps]="queryProps"
                       [configuration]="tableConfiguration" />
  `,
  standalone: false,
})
export class GlobalSearchWorkPackagesComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  readonly searchTerm = input('', { transform: stringAttribute('') });

  readonly scope = input<SearchScope|undefined, string|null|undefined>(undefined, {
    transform: (value) => (isSearchScope(value) ? value : undefined),
  });

  readonly searchMode = input<SearchMode, string|null|undefined>('text', {
    transform: (value) => (value === 'semantic' ? 'semantic' : 'text'),
  });

  readonly semanticSearchAvailable = input(false, { transform: booleanAttributeOr(false) });

  public queryProps:Partial<QueryRequestParams>;

  readonly renderer= inject(Renderer2);
  readonly I18n= inject(I18nService);
  readonly halResourceService= inject(HalResourceService);
  readonly wpTableFilters= inject(WorkPackageViewFiltersService);
  readonly querySpace= inject(IsolatedQuerySpace);
  readonly currentProject= inject(CurrentProjectService);
  readonly cdRef= inject(ChangeDetectorRef);

  public tableConfiguration:WorkPackageTableConfigurationObject = {
    actionsColumnEnabled: false,
    columnMenuEnabled: true,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    withFilters: true,
    showFilterButton: true,
    filterButtonText: this.I18n.t('js.button_advanced_filter'),
  };

  ngOnInit():void {
    this.wpTableFilters.semanticSearchAvailable = this.semanticSearchAvailable();
    this.wpTableFilters.semanticSearchEnabled = this.isSemanticSearch;
    this.setQueryProps();
  }

  public get isSemanticSearch():boolean {
    return this.searchMode() === 'semantic';
  }

  private get useSemanticSearch():boolean {
    return this.isSemanticSearch && this.semanticSearchAvailable();
  }

  private setQueryProps():void {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    const filters:any[] = [];
    let columns = ['id', 'project', 'subject', 'type', 'status', 'updatedAt'];

    if (this.searchTermIsId) {
      filters.push({
        id: {
          operator: '=',
          values: [this.searchTermWithoutHash],
        },
      });
    } else if (this.searchTerm().length > 0) {
      filters.push({
        [this.useSemanticSearch ? 'semanticSearch' : 'search']: {
          operator: '**',
          values: [this.searchTerm()],
        },
      });
    }

    if (this.scope() === 'current_project') {
      filters.push({
        subprojectId: {
          operator: '!*',
          values: [],
        },
      });
      columns = ['id', 'subject', 'type', 'status', 'updatedAt'];
    }

    if (this.scope() === '' && this.currentProject.id) {
      filters.push({
        subprojectId: {
          operator: '*',
          values: [],
        },
      });
    }

    this.queryProps = {
      'columns[]': columns,
      filters: JSON.stringify(filters),
      sortBy: JSON.stringify(this.useSemanticSearch ? [['semanticSimilarity', 'asc']] : [['updatedAt', 'desc']]),
      showHierarchies: false,
    };
  }

  public get searchTermIsId():boolean {
    return this.searchTermWithoutHash !== this.searchTerm();
  }

  public get searchTermWithoutHash():string {
    const searchTerm = this.searchTerm();
    if (/^#(\d+)/.exec(searchTerm)) {
      return searchTerm.substr(1);
    }
    return searchTerm;
  }
}
