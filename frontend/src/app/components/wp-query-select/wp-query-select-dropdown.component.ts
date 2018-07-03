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
import {States} from '../states.service';
import {WorkPackagesListService} from '../wp-list/wp-list.service';
import {WorkPackagesListChecksumService} from '../wp-list/wp-list-checksum.service';
import {StateService, TransitionService} from '@uirouter/core';
import {Component, Inject, OnInit, OnDestroy, Attribute, ElementRef, Injector} from "@angular/core";
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';

interface IAutocompleteItem {
  label:any;
  query:any;          //QueryResource|null
  query_props:any;    //string|null
}

interface IQueryAutocompleteJQuery extends JQuery {
  querycomplete({}):void;
}



@Component({
  selector: 'wp-query-select',
  templateUrl: './wp-query-select.template.html'
})
export class WorkPackageQuerySelectDropdownComponent implements OnInit, OnDestroy {
  public loaded = false;
  public text = {
    loading: this.I18n.t('js.ajax.loading'),
    label: this.I18n.t('js.toolbar.search_query_label'),
    scope_default: this.I18n.t('js.label_default_queries'),
    scope_starred: this.I18n.t('js.label_starred_queries'),
    scope_global: this.I18n.t('js.label_global_queries'),
    scope_private: this.I18n.t('js.label_custom_queries'),
    no_results: this.I18n.t('js.work_packages.query.text_no_results')
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
              readonly loadingIndicator:LoadingIndicatorService) {

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
      let sortedQueries = _.reverse(_.sortBy(collection.elements, 'public'));
      let autocompleteValues:IAutocompleteItem[] = _.map(sortedQueries, (query:any) => { return { label: query.name, query: query, query_props: null }; } );
      let defaultQuery = { label: 'All open', query: null, query_props: '' };
      let ganttQuery = { label: 'Gantt Chart', query: null, query_props: '%7B%22tv%22%3Atrue%7D' };
      let wishListQuery = { label: 'Wish List', query: null, query_props: '%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22,%22version%22%5D,%22tzl%22:%22days%22,%22hi%22:true,%22g%22:%22%22,%22t%22:%22parent:asc%22,%22f%22:%5B%7B%22n%22:%22status%22,%22o%22:%22o%22,%22v%22:%5B%5D%7D,%7B%22n%22:%22updatedAt%22,%22o%22:%22w%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D' };
      let latestActivityQuery = { label: 'Latest Activity', query: null, query_props: ''};
      let staticQueries:IAutocompleteItem[] = [defaultQuery, ganttQuery, wishListQuery, latestActivityQuery]

      this.setupAutoCompletion(staticQueries.concat(autocompleteValues));

      this.setLoaded();
    });
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
      },
      response: (event:any, ui:any) => {
        // Show the noResults span if we don't have any matches
        noResults.toggle(ui.content.length === 0);
      },
      close : function (event:any, ui:any) {
        if (!jQuery("ul.ui-autocomplete").is(":visible")) {
            jQuery("ul.ui-autocomplete").show();
        }
      },
      appendTo: '.search-query-wrapper',
      classes: {
        'ui-autocomplete': '-inplace'
      },
      autoFocus: true,
      minLength: 0
    });
  }

  private defineJQueryQueryComplete() {
    let sortArray = (items:IAutocompleteItem[]) => {
      let starredQueries:IAutocompleteItem[] = [];
      let publicQueries:IAutocompleteItem[] = [];
      let privateQueries:IAutocompleteItem[] = [];
      let defaultQueries:IAutocompleteItem[] = [];

      _.each(items, option => {
        var query = option.query;
        if (query) {  // If there is a query, check if it is starred, public or private
          if (query.starred) {
            starredQueries.push(option);
          } else {
          	if (query.public) { publicQueries.push(option); }
            else { privateQueries.push(option); }
          }
        } else { defaultQueries.push(option); }
      });
      let sortedQueries:IAutocompleteItem[] = starredQueries.concat(defaultQueries).concat(publicQueries).concat(privateQueries);
      return sortedQueries;
    }

    let labelFunction = (option:IAutocompleteItem) => {
      if (option.query) {
        if (option.query.starred) {
        	return this.text.scope_starred;
        } else {
        	if (option.query.public) {
         		return this.text.scope_global;
          } else {
        		return this.text.scope_private;
        	}
        }
      } else {
        return this.text.scope_default;
      }

    };

    jQuery.widget('custom.querycomplete', jQuery.ui.autocomplete, {
      _create: function(this:any) {
        this._super();
        this.widget().menu( 'option', 'items', '> :not(.ui-autocomplete--category)' );
        this._search('');
      },
      _renderMenu: function(this:any, ul:any, items:IAutocompleteItem[]) {
        let sortedArray = sortArray(items);
        let currentCategory:string;
        let category:any;

        _.each(sortedArray, option => {
          // Check if item has same category as previous item and if not insert a new category label in the list
          if (currentCategory !== labelFunction(option)) {
            currentCategory = labelFunction(option);
            category = ul.append( "<a tabindex='0' aria-hidden='true'></a>" +
                                      "<li class='ui-autocomplete--category' title='" + currentCategory + "'>" + currentCategory + "</li>");

          }
          this._renderItemData(ul, option, currentCategory);
        });
        category.on('click', (event:any) => {
          let lisFromCategory = jQuery(event.target).nextUntil(jQuery('.ui-autocomplete--category'), '.ui-menu-item' );
          lisFromCategory.toggleClass('hidden');
          jQuery(event.target).prev('a').toggleClass("-collapsed");
        });
      }
    });
  }

  private loadQuery(item:IAutocompleteItem) {
    this.wpListChecksumService.clear();

    let promise:Promise<QueryResource>;

    if (!item.query) {
      promise = this.wpListService.fromQueryParams({query_props: item.query_props}, this.projectIdentifier);
    } else {
      promise = this.wpListService.reloadQuery(item.query);
    }

    this.loadingIndicator.table.promise = promise;
  }

  private setLoaded() {
    this.loaded = true;
    this.text.loading = '';
  }
}
