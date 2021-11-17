// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { map } from 'rxjs/operators';
import { BehaviorSubject, combineLatest, Observable } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { IOpSidemenuItem } from 'core-app/shared/components/sidemenu/sidemenu.component';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageStaticQueriesService } from 'core-app/features/work-packages/components/wp-query-select/wp-static-queries.service';

export const wpQuerySelectSelector = 'wp-query-select';

@Component({
  selector: wpQuerySelectSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-query-select.template.html',
})
export class WorkPackageQuerySelectDropdownComponent extends UntilDestroyedMixin implements OnInit {
  public text = {
    search: this.I18n.t('js.toolbar.search_query_label'),
    label: this.I18n.t('js.toolbar.search_query_label'),
    scope_default: this.I18n.t('js.label_default_queries'),
    scope_starred: this.I18n.t('js.label_starred_queries'),
    scope_global: this.I18n.t('js.label_global_queries'),
    scope_private: this.I18n.t('js.label_custom_queries'),
    no_results: this.I18n.t('js.work_packages.query.text_no_results'),
  };

  public $queries:Observable<IOpSidemenuItem[]>;

  private $queryCategories = new BehaviorSubject<IOpSidemenuItem[]>([]);

  private $search = new BehaviorSubject<string>('');

  private initialized = false;

  constructor(
    readonly apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    readonly states:States,
    readonly CurrentProject:CurrentProjectService,
    readonly wpStaticQueries:WorkPackageStaticQueriesService,
    readonly mainMenuService:MainMenuNavigationService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  public set search(input:string) {
    if (this.$search.value !== input) {
      this.$search.next(input);
    }
  }

  ngOnInit():void {
    // When activating the work packages submenu,
    // either initially or through click on the toggle, load the results
    this.mainMenuService
      .onActivate('work_packages', 'work_packages_query_select')
      .subscribe(() => this.initializeAutocomplete());

    this.$queries = combineLatest(
      this.$search,
      this.$queryCategories,
    )
      .pipe(
        map(([searchText, categories]) => categories
          .map((category) => {
            if (this.matchesText(category.title, searchText)) {
              return category;
            }

            const filteredChildren = category.children?.filter((query) => this.matchesText(query.title, searchText));
            return { title: category.title, children: filteredChildren, collapsible: true };
          })
          .filter((category) => category.children && category.children.length > 0)),
      );
  }

  private initializeAutocomplete():void {
    if (this.initialized) {
      return;
    }

    // Set focus on collapsible menu's back button.
    // This improves accessibility for blind users to tell them their current location.
    const buttonArrowLeft = document.getElementById('main-menu-work-packages-wrapper')?.parentElement
      ?.getElementsByClassName('main-menu--arrow-left-to-project')[0] as HTMLElement;
    if (buttonArrowLeft) {
      buttonArrowLeft.focus();
    }

    this.updateMenuOnChanges();
    this.initializeQueries();
    this.initialized = true;
  }

  // noinspection JSMethodCanBeStatic
  private matchesText(text:string, searchText:string):boolean {
    return text.toLowerCase().includes(searchText.toLowerCase());
  }

  private initializeQueries():void {
    const categories:{ [category:string]:IOpSidemenuItem[] } = {
      starred: [],
      default: [],
      public: [],
      private: [],
    };

    // TODO: use global query store
    this.apiV3Service
      .queries
      .filterNonHidden(this.CurrentProject.identifier)
      .pipe(this.untilDestroyed())
      .subscribe((queryCollection) => {
        queryCollection.elements.forEach((query) => {
          let cat = 'private';
          if (query.public) {
            cat = 'public';
          }
          if (query.starred) {
            cat = 'starred';
          }

          categories[cat].push(WorkPackageQuerySelectDropdownComponent.toOpSideMenuItem(query));
        });

        this.$queryCategories.next([
          { title: this.text.scope_starred, children: categories.starred, collapsible: true },
          { title: this.text.scope_default, children: this.wpStaticQueries.all, collapsible: true },
          { title: this.text.scope_global, children: categories.public, collapsible: true },
          { title: this.text.scope_private, children: categories.private, collapsible: true },
        ]);
      });
  }

  private static toOpSideMenuItem(query:QueryResource):IOpSidemenuItem {
    return {
      title: query.name,
      uiSref: 'work-packages',
      uiParams: { query_id: query.id, query_props: '' },
    };
  }

  // Listens on all changes of queries (via an observable in the service), e.g. delete, create, rename, toggle starred
  private updateMenuOnChanges() {
    this.states.changes.queries
      .pipe(this.untilDestroyed())
      .subscribe(() => this.initializeQueries());
  }
}
