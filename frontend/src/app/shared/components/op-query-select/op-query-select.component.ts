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
  ElementRef,
  Input,
  OnInit,
} from '@angular/core';
import { map } from 'rxjs/operators';
import {
  BehaviorSubject,
  combineLatest,
  Observable,
} from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { IOpSidemenuItem } from 'core-app/shared/components/sidemenu/sidemenu.component';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { StaticQueriesService } from 'core-app/shared/components/op-query-select/op-static-queries.service';

export const opQuerySelectSelector = 'op-query-select';

@DatasetInputs
@Component({
  selector: opQuerySelectSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './op-query-select.template.html',
})
export class QuerySelectComponent extends UntilDestroyedMixin implements OnInit {
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

  @Input() menuItems:string[] = [];

  @Input() projectIdentifier:string;

  @Input() baseRoute:string;

  private $queryCategories = new BehaviorSubject<IOpSidemenuItem[]>([]);

  private $search = new BehaviorSubject<string>('');

  private initialized = false;

  constructor(
    readonly elementRef:ElementRef,
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly states:States,
    readonly opStaticQueries:StaticQueriesService,
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
      .onActivate(...this.menuItems)
      .subscribe(() => this.initializeAutocomplete());

    this.$queries = combineLatest(
      this.$search,
      this.$queryCategories,
    )
      .pipe(
        map(([searchText, categories]) => categories
          .map((category) => {
            if (QuerySelectComponent.matchesText(category.title, searchText)) {
              return category;
            }

            const filteredChildren = category.children
              ?.filter((query) => QuerySelectComponent.matchesText(query.title, searchText));
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

  private static matchesText(text:string, searchText:string):boolean {
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
      .filterNonHidden(this.projectIdentifier)
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

          categories[cat].push(this.toOpSideMenuItem(query));
        });

        const staticQueries = this.opStaticQueries.getStaticQueries(this.baseRoute);
        this.$queryCategories.next([
          { title: this.text.scope_starred, children: categories.starred, collapsible: true },
          { title: this.text.scope_default, children: staticQueries, collapsible: true },
          { title: this.text.scope_global, children: categories.public, collapsible: true },
          { title: this.text.scope_private, children: categories.private, collapsible: true },
        ]);
      });
  }

  private toOpSideMenuItem(query:QueryResource):IOpSidemenuItem {
    return {
      title: query.name,
      uiSref: this.baseRoute,
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
