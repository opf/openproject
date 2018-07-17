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

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
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
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {BehaviorSubject} from 'rxjs/BehaviorSubject';
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {distinctUntilChanged} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';

export interface IAutocompleteItem {
  auto_id?:any;
  label:any;
  query:any;
  query_props:any;
  category?: any;
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

  constructor(readonly element:ElementRef,
              readonly QueryDm:QueryDmService,
              readonly $state:StateService,
              readonly $transitions:TransitionService,
              readonly I18n:I18nService,
              readonly states:States,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly wpListComponent:WorkPackagesListComponent,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly pathHelper:PathHelperService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService) {

  }

  public ngOnInit() {
    this.projectIdentifier = this.element.nativeElement.getAttribute("identifier");
    jQuery(document).ready(() => {
      let toggler = jQuery('#main-menu-work-packages-wrapper .toggler');
      toggler.on('click', event => {
       this.openMenu();
      });
    });
    this.unregisterTransitionListener = this.$transitions.onSuccess({}, (transition) => {
      this.openMenu();
    });
  }

  ngOnDestroy() {
    this.unregisterTransitionListener();
  }

  private openMenu() {
    this.loadQueries().then(collection => {
      this.setupAutoCompletion(this.transformQueries(collection));
      this.setLoaded();
    });
  }

  private transformQueries(collection:CollectionResource) {
    let autocompleteValues:IAutocompleteItem[] = _.map(collection.elements, (query:any) => {
      return { auto_id: null, label: query.name, query: query, query_props: null, category: null};
    });
    // Set a unique numeric identifier for every query in the collection
    // Add the right category to every item and order all queries by categories
    return this.sortQueries(this.setAutocompleterId(autocompleteValues));
  }

  private updateMenuOnChanges(input:any) {
    this.wpListService.queryChanges$
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe( () => {
        this.loadQueries().then(collection => {
          input.querycomplete("option", { source: this.transformQueries(collection) });
          input.querycomplete("search", input.val());
        });
      });
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
    return _.map(  this.wpStaticQueries.all, (query:any) => {
      query.auto_id = idCounter++;
      query.category = null;
      return query;
    });
  }

  // Filter the collection by categories, add the correct categories to every item of the filtered array
  // Sort every category array alphabetically, except the default queries
  // Concat all categories in the right order
  private sortQueries(items:IAutocompleteItem[]):IAutocompleteItem[] {
    let sortedQueries:IAutocompleteItem[] = [];
    sortedQueries = sortedQueries.concat(
      this.sortByLabel(items.filter(item => item.query && item.query.starred).map(item => this.setCategory(item, 'starred'))),
      items.filter(item => !item.query).map(item => this.setCategory(item, 'default')),
      this.sortByLabel(items.filter(item => item.query && !item.query.starred && item.query.public).map(item => this.setCategory(item, 'public'))),
      this.sortByLabel(items.filter(item => item.query && !item.query.starred && !item.query.public).map(item => this.setCategory(item, 'private')))
    );
    return sortedQueries;
  }

  // Sort a given array of items by the value of their label attribute
  private sortByLabel(items:IAutocompleteItem[]) {
    return items.sort(function(a, b) {
      let labelA = a.label.toUpperCase(); // ignore upper and lowercase
      let labelB = b.label.toUpperCase(); // ignore upper and lowercase
      if (labelA < labelB) { return -1; }
      if (labelA > labelB) { return 1; }
      return 0;
    });
  }

  private setCategory(item:IAutocompleteItem, categoryString:string):IAutocompleteItem {
    return { auto_id: item.auto_id, label: item.label, query: item.query, query_props: item.query_props, category: categoryString } ;
  }

  private loadQueries() {
    return this.QueryDm.all(this.projectIdentifier);
  }

  private setupAutoCompletion(autocompleteValues:IAutocompleteItem[]) {
    this.defineJQueryQueryComplete();

    let input = jQuery('#query-title-filter') as IQueryAutocompleteJQuery;
    let noResults = jQuery('.query-select-dropdown--no-results');

    input.querycomplete({
      delay: 0,
      source: autocompleteValues,
      select: (ul:any, selected:{item:IAutocompleteItem}) => {
        this.loadQuery(selected.item);
        this.highlightSelected(selected.item);
        return false; // Don't show title of selected query in the input field
      },
      response: (event:any, ui:any) => {
        // Show the noResults span if we don't have any matches
        noResults.toggleClass('hidden', !(ui.content.length === 0));
      },
      close : function (event:any, ui:any) {
        if (!jQuery("ul.ui-autocomplete").is(":visible") && (noResults.hasClass('hidden'))) {
            jQuery("ul.ui-autocomplete").show();
        }
      },
      appendTo: '.search-query-wrapper',
      classes: {
        'ui-autocomplete': '-inplace'
      },
      autoFocus: false,
      minLength: 0
    });

    this.updateMenuOnChanges(input);
  }

  private defineJQueryQueryComplete() {
    let currentQueryParams = parseInt(this.$state.params.query_id);
    let thisComponent = this;

    jQuery.widget('custom.querycomplete', jQuery.ui.autocomplete, {
      _create: function(this:any) {
        this._super();
        this.widget().menu( 'option', 'items', '> :not(.ui-autocomplete--category)' );
        this._search('');
      },
      _renderItem: function(ul:any, item:IAutocompleteItem) {
        let li = jQuery("<li class='ui-menu-item " + item.category + "' auto_id='" + item.auto_id + "'><div class='ui-menu-item-wrapper' tabindex='0'>" + item.label + "</div></li>");
        li.data('ui-autocomplete-item', item);  // Focus method of autocompleter needs this data for accessibility - if not set, it will throw errors

        if (currentQueryParams && item.query && item.query.id === currentQueryParams) {
          li.addClass('selected');  // Set class 'selected' on initial rendering of the menu
        }
        return ul.append(li);
      },
      _renderMenu: function(this:any, ul:any, items:IAutocompleteItem[]) {
        let currentCategory:string;
        let categoryDOMElement:any;

        _.each(items, option => {
          // Check if item has same category as previous item and if not insert a new category label in the list
          if (option.category !== currentCategory) {
            currentCategory = option.category;
            let label = thisComponent.labelFunction(currentCategory);
            categoryDOMElement = ul.append( "<a tabindex='0' aria-hidden='true'></a>" +
                                            "<li class='ui-autocomplete--category " + option.category + "' title='" + label + "'>" + label + "</li>");
          }
          this._renderItemData(ul, option);
        });
        /// Add an Eventlistener on all categories to show and hide the list elements from this category
        thisComponent.setToggleCategories(categoryDOMElement);
      }
    });
  }

  private labelFunction(category:string):string {
    switch (category) {
      case 'starred': return this.text.scope_starred;
      case 'public': return this.text.scope_global;
      case 'private': return this.text.scope_private;
      case 'default': return this.text.scope_default;
      default: return '';
    }
  }

  private setToggleCategories(category:any) {
    category.on('click', (event:JQueryEventObject) => {
      let clickedCategory = event.target.classList[1];
      jQuery('.' + clickedCategory).toggleClass('hidden');
      jQuery(event.target).prev('a').toggleClass("-collapsed");
    });
  }

  // On click of a menu item, load requested query
  private loadQuery(item:IAutocompleteItem) {
    // Case 1: In the main wp list view, load requested without refreshing the page
    if (this.$state.includes('work-packages.list')) {
      this.wpListChecksumService.clear();

      let promise:any = null;

      if (item.auto_id === this.wpStaticQueries.summary.auto_id) {
        window.location.href = this.pathHelper.projectWorkPackagesPath(this.projectIdentifier) + '/report';
        //this.$state.go('work-packages.report');
      }
      else if (!item.query) {
        promise = this.wpListService.fromQueryParams({query_props: item.query_props}, this.projectIdentifier);
      } else {
        promise = this.wpListService.reloadQuery(item.query);
      }
      this.loadingIndicator.table.promise = promise;
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

  private setLoaded() {
    this.loaded = true;
    this.text.search = '';
  }
}
