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
import {Component, Inject, OnInit, OnDestroy, Attribute, ElementRef, Injector} from "@angular/core";
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";

export interface IAutocompleteItem {
  auto_id?:any;
  label:any;
  query:any;
  query_props:any;
  category?:any;
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
  public loaded = false;
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

  private projectIdentifier:string;

  private hiddenCategories:any = [];

  private reportsBodySelector = '.controller-work_packages\\/reports';


  constructor(readonly element:ElementRef,
              readonly QueryDm:QueryDmService,
              readonly $state:StateService,
              readonly $transitions:TransitionService,
              readonly I18n:I18nService,
              readonly states:States,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly pathHelper:PathHelperService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService) {
  }

  public ngOnInit() {
    this.projectIdentifier = this.element.nativeElement.getAttribute("identifier");

    jQuery(document).ready(() => {
      // If we start out outside of the work packages module,
      // we load the menu once the user clicks on the toggler next to the
      // work packages menu item.
      let toggler = jQuery('#main-menu-work-packages-wrapper .toggler');
      toggler.one('click', event => {
        this.openMenu();
      });
       // If we start out on the work package report/summary page
      // open the menu at once. Rails is instructed to mark
      // the "work_packages" menu item to be selected.
      if (jQuery('body').is(this.reportsBodySelector)) {
        this.openMenu();
      }
    });
    // If we start on any work packages page, we open the menu on
    // a transition, meaning initially.
    this.unregisterTransitionListener = this.$transitions.onSuccess({}, (transition) => {
      this.openMenu();
      // We only want to load the menu once.
      this.unregisterTransitionListener();
    });

    // Register click handler on results
    this.addClickHandler();
  }


  ngOnDestroy() {
    this.unregisterTransitionListener();
  }

  private openMenu() {
    let input = jQuery('#query-title-filter') as IQueryAutocompleteJQuery;
    this.setupAutoCompletion(input);
    this.updateMenuOnChanges(input);
  }

  private transformQueries(collection:CollectionResource) {
    let autocompleteValues:IAutocompleteItem[] = _.map(collection.elements, (query:any) => {
      return { auto_id: null, label: query.name, query: query, query_props: null, category: null };
    });
    // Set a unique numeric identifier for every query in the collection
    // Add the right category to every item and order all queries by categories
    return this.sortQueries(this.setAutocompleterId(autocompleteValues));
  }

  private setAutocompleterId(queries:any):IAutocompleteItem[] {
    let idCounter = 0;
    _.each(queries, query => {
      query.auto_id = idCounter;
      idCounter++;
    });
    queries = queries.concat(this.setStaticQueries(idCounter));
    return queries;
  }

  // Create the static queries and return them as one Array
  private setStaticQueries(idCounter:number):IAutocompleteItem[] {
    let all = this.wpStaticQueries.all;
    // If no project is selected, delete summary from collection (for there is no summary for the global workpackages)
    if (!this.projectIdentifier) {
      all = _.filter( this.wpStaticQueries.all, item => item !== this.wpStaticQueries.summary);
    }
    return _.map( all, (item:any) => {
      item.auto_id = idCounter++;
      item.category = null;
      return item;
    });
  }

  // Filter the collection by categories, add the correct categories to every item of the filtered array
  // Sort every category array alphabetically, except the default queries
  private sortQueries(items:IAutocompleteItem[]):IAutocompleteItem[] {
    let starredQueries = this.setCategory(items.filter(item => item.query && item.query.starred), 'starred');
    let defaultQueries = this.setCategory(items.filter(item => !item.query), 'default');
    let publicQueries = this.setCategory(items.filter(item => item.query && !item.query.starred && item.query.public), 'public');
    let privateQueries = this.setCategory(items.filter(item => item.query && !item.query.starred && !item.query.public), 'private');

    // Concat all categories in the right order
    let sortedQueries:IAutocompleteItem[] = _.concat(
      this.sortByLabel(starredQueries), defaultQueries, this.sortByLabel(publicQueries), this.sortByLabel(privateQueries)
    );
    return sortedQueries;
  }

  // Sort a given array of items by the value of their label attribute
  private sortByLabel(items:IAutocompleteItem[]):IAutocompleteItem[] {
    return items.sort(function(a, b) {
      let labelA = a.label.toUpperCase(); // ignore upper and lowercase
      let labelB = b.label.toUpperCase(); // ignore upper and lowercase
      if (labelA < labelB) { return -1; }
      if (labelA > labelB) { return 1; }
      return 0;
    });
  }

  private setCategory(items:IAutocompleteItem[], categoryName:string):IAutocompleteItem[] {
    return items.map(item => {
      item.category = categoryName;
      return item;
    });
  }

  private loadQueries() {
    return this.QueryDm.all(this.projectIdentifier);
  }

  private setupAutoCompletion(input:IQueryAutocompleteJQuery) {
    this.defineJQueryQueryComplete();

    input.querycomplete({
      delay: 100,
      // The values are added later by the listener also covering
      // the changes to queries (updateMenuOnChanges()).
      source: [],
      select: (ul:any, selected:{item:IAutocompleteItem}) => {
        this.loadQuery(selected.item);
        this.highlightSelected(selected.item);
        return false; // Don't show title of selected query in the input field
      },
      response: (event:any, ui:any) => {
        // Show the noResults span if we don't have any matches
        this.noResults = (ui.content.length === 0);
      },
      close : (event:any, ui:any) => {
        if (!jQuery("ul.ui-autocomplete").is(":visible") && this.noResults) {
            jQuery("ul.ui-autocomplete").show();
        }
      },
      appendTo: '.wp-query-menu--search-container',
      classes: {
        'ui-autocomplete': 'wp-query-menu--search-ul -inplace',
        'ui-menu-divider': 'wp-query-menu--category-icon'
      },
      autoFocus: false,
      minLength: 0
    });
  }

  private defineJQueryQueryComplete() {
    let thisComponent = this;

    jQuery.widget('custom.querycomplete', jQuery.ui.autocomplete, {
      _create: function(this:any) {
        this._super();
        this.widget().menu( 'option', 'items', '> :not(.ui-autocomplete--category)' );
      },
      _renderItem: function(this:{}, ul:any, item:IAutocompleteItem) {
        const link = jQuery('<a>')
          .addClass('wp-query-menu--item-link')
          .attr('href', thisComponent.buildQueryItemUrl(item))
          .text(item.label);

        const div = jQuery('<div>')
          .addClass('wp-query-menu--item-wrapper')
          .append(link);

        const li = jQuery('<li>')
          .addClass(`ui-menu-item ui-menu-item-${item.auto_id} wp-query-menu--item`)
          .attr('data-auto-id', item.auto_id)
          .attr('data-category', item.category)
          .data('ui-autocomplete-item', item)  // Focus method of autocompleter needs this data for accessibility - if not set, it will throw errors
          .append(div)
          .appendTo(ul);

        thisComponent.setInitialHighlighting(li, item);

        return li;
      },
      _renderMenu: function(this:any, ul:any, items:IAutocompleteItem[]) {
        let currentCategory:string;

        _.each(items, option => {
          // Check if item has same category as previous item and if not insert a new category label in the list
          if (option.category !== currentCategory) {
            currentCategory = option.category;
            let label = thisComponent.labelFunction(currentCategory);

            ul.append(`<a tabindex="0" class="wp-query-menu--category-icon wp-query-menu--category-toggle" data-category="${currentCategory}" aria-hidden="true"></a>`);
            jQuery('<li>')
              .addClass('ui-autocomplete--category wp-query-menu--category-toggle ellipsis')
              .attr('title', label)
              .attr('data-category', option.category)
              .text(label)
              .appendTo(ul);
          }
          this._renderItemData(ul, option);
        });
        /// Add an Eventlistener on all categories to show and hide the list elements from this category
        thisComponent.setToggleCategories();
      }
    });
  }

  // Set class 'selected' on initial rendering of the menu
  // Case 1: Wp menu is opened from somewhere else in the project -> Compare query params with url params and highlight selected
  // Case 2: Click on menu item 'Work Packages' (query 'All open' is opened on default) -> highlight 'All open'
  private setInitialHighlighting(currentLi:JQuery, item:IAutocompleteItem) {
    let currentQueryParams:number = parseInt(this.$state.params.query_id);
    let onWorkPackagesPage:boolean = this.$state.includes('work-packages');

    if (item.query && item.query.id === currentQueryParams ||
        !item.query && item.query_props === this.$state.params.query_props ||
        onWorkPackagesPage && !this.$state.params.query_props && !this.$state.params.query_id && item.label === 'All open') {
      currentLi.addClass('selected');
    }
  }

  private labelFunction(category:string):string {
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
      .subscribe( () => {
        this.loadQueries().then(collection => {
          // Update the complete collection
          input.querycomplete("option", { source: this.transformQueries(collection) });
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

  // Toggle category: hide all items with the clicked category and change direction of arrow
  private setToggleCategories() {

  }

  private expandCollapseCategory(category:string) {
    jQuery(`[data-category="${category}"]`).toggleClass('-hidden');
    jQuery(`.wp-query-menu--category-icon[data-category="${category}"]`).toggleClass('-collapsed');
  }

  // On click of a menu item, load requested query
  private loadQuery(item:IAutocompleteItem) {
    // Case 1: In the main wp list view, load requested without refreshing the page
    if (this.$state.includes('work-packages.list')) {
      this.wpListChecksumService.clear();

      let promise:Promise<QueryResource>|null = null;

      if (item.auto_id === this.wpStaticQueries.summary.auto_id) {
        window.location.href = this.pathHelper.projectWorkPackagesPath(this.projectIdentifier) + '/report';
      }
      else if (!item.query) { // default query
        if (this.projectIdentifier) {
          this.$state.go('work-packages.list', { query_props: item.query_props, projectPath: this.projectIdentifier });
          promise = this.wpListService.fromQueryParams({query_props: item.query_props}, this.projectIdentifier);
        } else {
          this.$state.go('work-packages.list', { query_props: item.query_props });
          promise = this.wpListService.fromQueryParams({query_props: item.query_props});
        }
      } else {
        promise = this.wpListService.reloadQuery(item.query);
      }
      this.loadingIndicator.table.promise = promise!;
    }
    // Case 2: In a subpage of the wp site, go back to wp main page to open the requested query (without refreshing)
    else if (this.$state.includes('work-packages')) {
      this.goBackToListView(item);
    }
    // Case 3: We are somewhere else in the project - on click of a menu item reload window with requested query
    else {
      this.reloadWindow(item);
    }
  }

  private buildQueryItemUrl(item:IAutocompleteItem):string {
    if (item.auto_id === this.wpStaticQueries.summary.auto_id) {
      return this.pathHelper.projectWorkPackagesPath(this.projectIdentifier) + '/report';
    }

    if (item.query) {
      // Saved query resource -> Reset to query id with empty query_props
      return this.$state.href('work-packages.list', { query_id: item.query.id, query_props: null });
    } else {
      // Default query
      return this.$state.href('work-packages.list', { query_props: item.query_props });
    }
  }

  private goBackToListView(item:IAutocompleteItem) {
    // Check if element has query or is a static query
    let requestedQuery;
    if (!item.query) {
      requestedQuery = { query_props: item.query_props };
    } else {
      requestedQuery = { query_id: item.query.id };
    }
    this.$state.go('work-packages.list', requestedQuery);
  }

  // Set url to work packages page depending on current project path
  private reloadWindow(item:IAutocompleteItem) {
    if (this.projectIdentifier) {
      window.location.href = this.pathHelper.projectWorkPackagesPath(this.projectIdentifier) + this.subpathToItem(item);
    } else {
      window.location.href = this.pathHelper.workPackagesPath() + this.subpathToItem(item);
    }
  }


  private subpathToItem(item:IAutocompleteItem):string {
    if (!item.query) {
      return '?query_props=' + item.query_props;
    } else {
      return '?query_id=' + item.query.id;
    }
  }

  private highlightSelected(item:IAutocompleteItem) {
    // Remove old selection
    jQuery(".ui-menu-item").removeClass('selected');
    //Find selected element in DOM and highlight it
    jQuery(("[auto_id=" + item.auto_id + "]")).addClass('selected');
  }

  /**
   * When clicking an item with meta keys,
   * avoid its propagation.
   *
   */
  private addClickHandler() {
    const container = jQuery(this.element.nativeElement).find('.wp-query-menu--search-container');

    container
        .on('click', '.ui-menu-item a', (evt:JQueryEventObject) => {
          if (LinkHandling.isClickedWithModifier(evt)) {
            evt.stopImmediatePropagation();
          }

          return true;
        })
      .on('click', '.wp-query-menu--category-toggle', (evt:JQueryEventObject) => {
        const target = jQuery(evt.target);
        const clickedCategory = target.data('category');

        if (clickedCategory) {
          this.expandCollapseCategory(clickedCategory);
        }
        // Remember all hidden catagories
        this.hiddenCategories = jQuery(".ui-autocomplete--category.hidden");

        evt.preventDefault();
        return false;
      });
  }
}

DynamicBootstrapper.register({ selector: 'wp-query-select', cls: WorkPackageQuerySelectDropdownComponent });
