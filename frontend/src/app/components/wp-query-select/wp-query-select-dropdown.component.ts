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

import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {States} from '../states.service';
import {WorkPackagesListService} from '../wp-list/wp-list.service';
import {WorkPackagesListChecksumService} from '../wp-list/wp-list-checksum.service';
import {WorkPackagesListComponent} from 'core-components/routing/wp-list/wp-list.component';
import {StateService, TransitionService} from '@uirouter/core';
import {Component, ElementRef, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {keyCodes} from "../../../../legacy/app/components/keyCodes.enum";
import {MainMenuToggleService} from "core-components/resizer/main-menu-toggle.service";

export type QueryCategory = 'starred' | 'public' | 'private' | 'default';

export interface IAutocompleteItem {
  // Some optional identifier
  identifier?:string;
  // Internal id for selecting items
  auto_id?:number;
  // The autocomplete item may be a static link (e.g., summary page)
  static_link?:string;
  // Label for the current locale
  label:string;
  // May be tied to a persisted query
  query?:QueryResource;
  // Or a loose map of query_props
  query_props?:any;
  // And is tied to a category
  category?:QueryCategory;
}

interface IQueryAutocompleteJQuery extends JQuery {
  querycomplete({}):void;
}


@Component({
  providers: [WorkPackagesListComponent],
  selector: 'wp-query-select',
  templateUrl: './wp-query-select.template.html'
})
export class WorkPackageQuerySelectDropdownComponent implements OnInit, OnDestroy {
  @ViewChild('wpQueryMenuSearchInput') _wpQueryMenuSearchInput:ElementRef;
  @ViewChild('queryResultsContainer') _queryResultsContainerElement:ElementRef;

  public loading = false;
  public noResults = false;

  public text = {
    search: this.I18n.t('js.toolbar.search_query_label'),
    label: this.I18n.t('js.toolbar.search_query_label'),
    scope_default: this.I18n.t('js.label_default_queries'),
    scope_starred: this.I18n.t('js.label_starred_queries'),
    scope_global: this.I18n.t('js.label_global_queries'),
    scope_private: this.I18n.t('js.label_custom_queries'),
    no_results: this.I18n.t('js.work_packages.query.text_no_results'),
  };
  private unregisterTransitionListener:Function;

  private projectIdentifier:string | null;

  private hiddenCategories:any = [];

  private reportsBodySelector = '.controller-work_packages\\/reports';

  private queryResultsContainer:JQuery;
  private buttonArrowLeft:JQuery;

  private searchInput:IQueryAutocompleteJQuery;

  private initialized = false;


  constructor(readonly element:ElementRef,
              readonly QueryDm:QueryDmService,
              readonly $state:StateService,
              readonly $transitions:TransitionService,
              readonly I18n:I18nService,
              readonly states:States,
              readonly CurrentProject:CurrentProjectService,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly pathHelper:PathHelperService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService,
              readonly toggleService:MainMenuToggleService) {
  }

  public ngOnInit() {
    this.queryResultsContainer = jQuery(this._queryResultsContainerElement.nativeElement);
    this.projectIdentifier = this.element.nativeElement.getAttribute('data-project-identifier');

    jQuery(document).ready(() => {
      // If we start out outside of the work packages module,
      // we load the menu once the user clicks on the toggler next to the
      // work packages menu item.
      let toggler = jQuery('#main-menu-work-packages-wrapper .toggler');
      toggler.one('click', event => {
        this.initializeAutocomplete();
      });
      // If we start out on the work package report/summary page
      // open the menu at once. Rails is instructed to mark
      // the "work_packages" menu item to be selected.
      if (jQuery('body').is(this.reportsBodySelector)) {
        this.initializeAutocomplete();
      }
    });
    // If we start on any work packages page, we open the menu on
    // a transition, meaning initially.
    this.unregisterTransitionListener = this.$transitions.onSuccess({}, (transition) => {
      this.initializeAutocomplete();
    });

    // Register click handler on results
    this.addClickHandler();
  }


  ngOnDestroy() {
    this.unregisterTransitionListener();
  }

  private initializeAutocomplete() {
    if (this.initialized) {
      return;
    }

    this.searchInput = jQuery(this._wpQueryMenuSearchInput.nativeElement) as any;
    this.buttonArrowLeft = jQuery('.main-menu--arrow-left-to-project', jQuery('#main-menu-work-packages-wrapper').parent()) as any;
    this.initialized = true;
    this.buttonArrowLeft.focus();
    this.setupAutoCompletion(this.searchInput);
    this.updateMenuOnChanges(this.searchInput);
  }

  private transformQueries(collection:CollectionResource) {
    let loadedQueries:IAutocompleteItem[] = _.map(collection.elements, (query:any) => {
      return {label: query.name, query: query, query_props: null};
    });

    // Add to the loaded set of queries the fixed set of queries for the current project context
    const combinedQueries = loadedQueries.concat(this.wpStaticQueries.all);
    return this.sortQueries(combinedQueries);
  }

  // Filter the collection by categories, add the correct categories to every item of the filtered array
  // Sort every category array alphabetically, except the default queries
  private sortQueries(items:IAutocompleteItem[]):IAutocompleteItem[] {
    // Concat all categories in the right order
    let categorized:{ [category:string]:IAutocompleteItem[] } = {
      // Starred / favored
      starred: [],
      // default
      default: [],
      // public
      public: [],
      // private
      private: []
    };

    let auto_id = 0;
    items.forEach((item):any => {
      item.auto_id = auto_id++;

      if (!item.query) {
        item.category = 'default';
        return categorized.default.push(item);
      }

      if (item.query.starred) {
        item.category = 'starred';
        return categorized.starred.push(item);
      }

      if (!item.query.starred && item.query.public) {
        item.category = 'public';
        return categorized.public.push(item);
      }

      if (!(item.query.starred || item.query.public)) {
        item.category = 'private';
        return categorized.private.push(item);
      }
    });

    return _.flatten(
      [categorized.starred, categorized.default, categorized.public, categorized.private]
        .map(items => this.sortByLabel(items))
    );
  }

  // Sort a given array of items by the value of their label attribute
  private sortByLabel(items:IAutocompleteItem[]):IAutocompleteItem[] {
    return items.sort((a, b) => a.label.toLowerCase().localeCompare(b.label.toLowerCase()));
  }

  private loadQueries() {
    return this.loadingPromise = this.QueryDm
      .all(this.CurrentProject.identifier);

  }

  private set loadingPromise(promise:Promise<any>) {
    this.loading = true;
    promise
      .then(() => this.loading = false)
      .catch(() => this.loading = false);
  }

  private setupAutoCompletion(input:IQueryAutocompleteJQuery) {
    this.defineJQueryQueryComplete();

    input.querycomplete({
      delay: 100,
      // The values are added later by the listener also covering
      // the changes to queries (updateMenuOnChanges()).
      source: [],
      select: (ul:any, selected:{ item:IAutocompleteItem }) => {
        return false; // Don't show title of selected query in the input field
      },
      response: (event:any, ui:any) => {
        // Show the noResults span if we don't have any matches
        this.noResults = (ui.content.length === 0);
      },
      close: (event:any, ui:any) => {
        const autocompleteUi = this.queryResultsContainer.find('ul.ui-autocomplete');
        if (!autocompleteUi.is(":visible") && !this.noResults) {
          autocompleteUi.show();
        }
      },
      focus: (_event:JQueryEventObject, ui:{ item:IAutocompleteItem }) => {
        let sourceEvent:any|null = _event;

        while(sourceEvent && sourceEvent.originalEvent) {
          sourceEvent = sourceEvent.originalEvent as any;
        }

        // Focus the given item, but only when we're using the keyboard.
        // With the mouse, hover shall suffice to avoid weird focus/hover combinations
        // e.g., https://community.openproject.com/wp/28197
        if (sourceEvent && sourceEvent.type === 'keydown') {
          this.queryResultsContainer
            .find(`#wp-query-menu-item-${ui.item.auto_id} .wp-query-menu--item-link`)
            .focus();
        }

        return false;
      },
      appendTo: '.wp-query-menu--results-container',
      classes: {
        'ui-autocomplete': 'wp-query-menu--search-ul -inplace',
        'ui-menu-divider': 'wp-query-menu--category-icon'
      },
      autoFocus: false, // Don't automatically select first entry since we 'open' the autocomplete on page load
      minLength: 0
    });
  }

  private defineJQueryQueryComplete() {
    let thisComponent = this;

    jQuery.widget('custom.querycomplete', jQuery.ui.autocomplete, {
      _create: function(this:any) {
        this._super();
        this.widget().menu('option', 'items', '.wp-query-menu--item');
        this._search('');
      },
      _renderItem: function(this:{}, ul:any, item:IAutocompleteItem) {
        const link = jQuery('<a>')
          .addClass('wp-query-menu--item-link')
          .attr('href', thisComponent.buildQueryItemUrl(item))
          .text(item.label);

        const li = jQuery('<li>')
          .addClass(`ui-menu-item wp-query-menu--item`)
          .attr('id', `wp-query-menu-item-${item.auto_id}`)
          .attr('data-category', item.category || '')
          .data('ui-autocomplete-item', item)  // Focus method of autocompleter needs this data for accessibility - if not set, it will throw errors
          .append(link)
          .appendTo(ul);

        thisComponent.setInitialHighlighting(li, item);

        return li;
      },
      _renderMenu: function(this:any, ul:any, items:IAutocompleteItem[]) {
        let currentCategory:QueryCategory;

        _.each(items, option => {
          // Check if item has same category as previous item and if not insert a new category label in the list
          if (option.category !== currentCategory) {
            currentCategory = option.category!;
            let label = thisComponent.labelFunction(currentCategory);

            ul.append(`<a tabindex="0" class="wp-query-menu--category-icon wp-query-menu--category-toggle" data-category="${currentCategory}" aria-hidden="true"></a>`);
            jQuery('<li>')
              .addClass('ui-autocomplete--category wp-query-menu--category-toggle ellipsis')
              .attr('title', label)
              .attr('data-category', currentCategory)
              .text(label)
              .appendTo(ul);
          }
          this._renderItemData(ul, option);
        });


        // Scroll to selected element if search is empty
        if (thisComponent.searchInput.val() === '') {
          let selected = thisComponent.queryResultsContainer.find('.wp-query-menu--item.selected');
          if (selected.length > 0) {
            setTimeout(() => selected[0].scrollIntoView({behavior: 'instant', block: 'center'}), 20);
          }
        }
      }
    });
  }

  // Set class 'selected' on initial rendering of the menu
  // Case 1: Wp menu is opened from somewhere else in the project -> Compare query params with url params and highlight selected
  // Case 2: Click on menu item 'Work Packages' (query 'All open' is opened on default) -> highlight 'All open'
  private setInitialHighlighting(currentLi:JQuery, item:IAutocompleteItem) {
    const params = this.getQueryParams(item);
    const currentId = this.$state.params.query_id;
    const currentProps = this.$state.params.query_props;
    let onWorkPackagesPage:boolean = this.$state.includes('work-packages');
    let onWorkPackagesReportPage:boolean = jQuery('body').hasClass('controller-work_packages/reports');

    // When the current ID is selected
    const currentIdSelected = params.query_id && (currentId || '').toString() === params.query_id.toString();

    // Case1: Static query props
    const matchesStaticQueryProps = !item.query && item.query_props && item.query_props === currentProps;

    // Case2: We're on the All open menu item
    const allOpen = onWorkPackagesPage && !currentId && !currentProps && item.identifier === 'all_open';

    // Case3: We're on the static summary page
    const onSummary = onWorkPackagesReportPage && item.identifier === 'summary';

    if (currentIdSelected || matchesStaticQueryProps || allOpen || onSummary) {
      currentLi.addClass('selected');
    }
  }

  private labelFunction(category:QueryCategory):string {
    switch (category) {
      case 'starred':
        return this.text.scope_starred;
      case 'public':
        return this.text.scope_global;
      case 'private':
        return this.text.scope_private;
      case 'default':
        return this.text.scope_default;
      default:
        return '';
    }
  }

  // Listens on all changes of queries (via an observable in the service), e.g. delete, create, rename, toggle starred
  // Update collection in autocompleter
  // Search again for the current value in input field to update the menu without loosing the current search results
  private updateMenuOnChanges(input:any) {
    this.wpListService.queryChanges$
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(() => {
        this.loadQueries().then(collection => {
          // Update the complete collection
          input.querycomplete("option", {source: this.transformQueries(collection)});
          // To visibly show the changes, we need to search again
          input.querycomplete("search", input.val());
          // To search an empty string would expand all categories again every time
          // Remember all previously hidden categories and set them again after updating the menu
          _.each(this.hiddenCategories, category => {
            let thisCategory:string = jQuery(category).attr("category");
            this.expandCollapseCategory(thisCategory);
          });
        });
      });
  }

  private expandCollapseCategory(category:string) {
    jQuery(`[data-category="${category}"]`).toggleClass('-hidden');
    jQuery(`.wp-query-menu--category-icon[data-category="${category}"]`).toggleClass('-collapsed');
  }

  // On click of a menu item, load requested query
  private loadQuery(item:IAutocompleteItem) {
    const params = this.getQueryParams(item);
    const currentId = _.toString(this.$state.params.query_id);
    let opts = {reload: false};

    const isStaticItem = !!item.identifier;
    const isSameItem = params.query_id && params.query_id === currentId.toString();


    // Ensure we're loading the query
    if (isStaticItem || isSameItem) {
      this.wpListChecksumService.clear();
    }

    if (isSameItem) {
      opts.reload = true;
    }

    this.$state.go(
      'work-packages.list',
      params,
      opts
    );

    this.toggleService.closeWhenOnMobile();
  }

  private getQueryParams(item:IAutocompleteItem) {
    let val:{ query_id:string | null, query_props:string | null, projects?:string, projectPath?:string } = {
      query_id: item.query ? _.toString(item.query.id) : null,
      query_props: item.query ? null : item.query_props,
    };

    if (this.projectIdentifier) {
      val.projects = 'projects';
      val.projectPath = this.projectIdentifier;
    }

    return val;
  }

  private buildQueryItemUrl(item:IAutocompleteItem):string {
    // Static item (such as summary)
    if (item.static_link) {
      return item.static_link;
    }

    const params = this.getQueryParams(item);
    return this.$state.href('work-packages.list', params);
  }

  private highlightSelected(item:IAutocompleteItem) {
    this.highlightBySelector(`#wp-query-menu-item-${item.auto_id}`);
  }

  private highlightBySelector(selector:string) {
    // Remove old selection
    this.queryResultsContainer.find(".ui-menu-item").removeClass('selected');
    //Find selected element in DOM and highlight it
    this.queryResultsContainer.find(selector).addClass('selected');
  }

  /**
   * When clicking an item with meta keys,
   * avoid its propagation.
   *
   */
  private addClickHandler() {
    this.queryResultsContainer
      .on('click keydown', '.ui-menu-item a', (evt:JQueryEventObject) => {
        if (evt.type === 'keydown' && evt.which !== keyCodes.ENTER) {
          return true;
        }

        // Find the item from the clicked element
        const target = jQuery(evt.target);
        const item:IAutocompleteItem = target
          .closest('.wp-query-menu--item')
          .data('ui-autocomplete-item');

        // Either the link is clicked with a modifier, then always cancel any propagation
        const clickedWithModifier = evt.type === 'click' && LinkHandling.isClickedWithModifier(evt);

        // Or the item is only a static link, then cancel propagation
        const isStatic = !!item.static_link;

        if (clickedWithModifier || isStatic) {
          evt.stopImmediatePropagation();

          if (evt.type === 'keydown') {
            window.location.href = target.attr('href');
          }
        } else {
          // If neither clicked with modifier nor static
          // Then prevent the default link handling and load the query
          evt.preventDefault();
          this.loadQuery(item);
          this.highlightSelected(item);
          return false;
        }

        return true;
      })
      .on('click keydown', '.wp-query-menu--category-toggle', (evt:JQueryEventObject) => {
        if (evt.type === 'keydown' && evt.which !== keyCodes.ENTER) {
          return true;
        }

        const target = jQuery(evt.target);
        const clickedCategory = target.data('category');

        if (clickedCategory) {
          this.expandCollapseCategory(clickedCategory);
        }

        // Remember all hidden catagories
        this.hiddenCategories = this.queryResultsContainer.find(".ui-autocomplete--category.hidden");

        evt.preventDefault();
        return false;
      });
  }
}

DynamicBootstrapper.register({selector: 'wp-query-select', cls: WorkPackageQuerySelectDropdownComponent});
