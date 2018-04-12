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
import {LoadingIndicatorService} from '../common/loading-indicator/loading-indicator.service';
import {WorkPackagesListChecksumService} from '../wp-list/wp-list-checksum.service';
import {StateService} from '@uirouter/core';
import {Component, Inject, OnInit} from "@angular/core";
import {
  $stateToken, FocusHelperToken, I18nToken,
  OpContextMenuLocalsToken
} from "core-app/angular4-transition-utils";
import {OpContextMenuLocalsMap} from "core-components/op-context-menu/op-context-menu.types";
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';

interface IAutocompleteItem {
  label:string;
  query:QueryResource;
}

interface IQueryAutocompleteJQuery extends JQuery {
  querycomplete({}):void;
}

@Component({
  template: require('!!raw-loader!./wp-query-select.template.html')
})
export class WorkPackageQuerySelectDropdownComponent implements OnInit {
  public loaded = false;
  public text = {
    loading: this.I18n.t('js.ajax.loading'),
    label: this.I18n.t('js.toolbar.search_query_label'),
    scope_global: this.I18n.t('js.label_global_queries'),
    scope_private: this.I18n.t('js.label_custom_queries'),
    no_results: this.I18n.t('js.work_packages.query.text_no_results')
  };

  constructor(readonly QueryDm:QueryDmService,
              @Inject($stateToken) readonly $state:StateService,
              @Inject(I18nToken) readonly I18n:op.I18n,
              @Inject(OpContextMenuLocalsToken) public locals:OpContextMenuLocalsMap,
              readonly states:States,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly loadingIndicator:LoadingIndicatorService) {

  }

  public ngOnInit() {
    this.loadQueries().then(collection => {
      let sortedQueries = _.reverse(_.sortBy(collection.elements, 'public'));
      let autocompleteValues = _.map(sortedQueries, (query:any) => { return { label: query.name, query: query }; } );

      this.setupAutoCompletion(autocompleteValues);

      this.setLoaded();
    });
  }

  private loadQueries() {
    return this.QueryDm.all(this.$state.params['projectPath']);
  }

  private setupAutoCompletion(autocompleteValues:IAutocompleteItem[]) {
    this.defineJQueryQueryComplete();

    let input = angular.element('#query-title-filter') as IQueryAutocompleteJQuery;
    let noResults = angular.element('.query-select-dropdown--no-results');

    input.querycomplete({
      delay: 0,
      source: autocompleteValues,
      select: (ul:any, selected:{item:IAutocompleteItem}) => {
        this.loadQuery(selected.item.query);
      },
      response: (event:any, ui:any) => {
        // Show the noResults span if we don't have any matches
        noResults.toggle(ui.content.length === 0);
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
    let labelFunction = (isPublic:boolean) => {
      if (isPublic) {
        return this.text.scope_global;
      } else {
        return this.text.scope_private;
      }
    };

    jQuery.widget('custom.querycomplete', jQuery.ui.autocomplete, {
      _create: function(this:any) {
        this._super();
        this.widget().menu( 'option', 'items', '> :not(.ui-autocomplete--category)' );
        this._search('');
      },
      _renderMenu: function(this:any, ul:any, items:IAutocompleteItem[] ) {
        let currentlyPublic:boolean;

        _.each(items, option => {
          var query = option.query;

          if ( query.public !== currentlyPublic ) {
            ul.append( "<li class='ui-autocomplete--category'>" + labelFunction(query.public) + '</li>' );
            currentlyPublic = query.public;
          }
          this._renderItemData( ul, option );
        });
      }
    });
  }

  private loadQuery(query:QueryResource) {
    this.wpListChecksumService.clear();
    this.loadingIndicator.table.promise = this.wpListService.reloadQuery(query);
    this.locals.service.close();
  }

  private setLoaded() {
    this.loaded = true;
    this.text.loading = '';
  }
}
