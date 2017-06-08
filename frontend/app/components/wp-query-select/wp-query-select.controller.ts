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

import {QueryDmService} from '../api/api-v3/hal-resource-dms/query-dm.service';
import {QueryResource} from '../api/api-v3/hal-resources/query-resource.service';
import {States} from '../states.service';
import {WorkPackagesListService} from '../wp-list/wp-list.service';
import {ContextMenuService} from '../context-menus/context-menu.service';
import {LoadingIndicatorService} from '../common/loading-indicator/loading-indicator.service';
import {WorkPackagesListChecksumService} from '../wp-list/wp-list-checksum.service';

interface IAutocompleteItem {
  label:string;
  query:QueryResource;
}

interface IQueryAutocompleteJQuery extends JQuery {
  querycomplete({}):void;
}

interface MyScope extends ng.IScope {
  loaded:boolean;
  i18n:MyI18n;
}

interface MyI18n {
  loading:string;
  label:string;
  scope_global:string;
  scope_private:string;
  no_results:string;
}

export class WorkPackageQuerySelectController {
  constructor(private $scope:MyScope,
              private QueryDm:QueryDmService,
              private $state:ng.ui.IStateService,
              private states:States,
              private wpListService:WorkPackagesListService,
              private contextMenu:ContextMenuService,
              private I18n:op.I18n,
              private wpListChecksumService:WorkPackagesListChecksumService,
              private loadingIndicator:LoadingIndicatorService) {

    this.$scope.loaded = false;
    this.$scope.i18n = {
      loading: I18n.t('js.ajax.loading'),
      label: I18n.t('js.toolbar.search_query_label'),
      scope_global: I18n.t('js.label_global_queries'),
      scope_private: I18n.t('js.label_custom_queries'),
      no_results: I18n.t('js.work_packages.query.text_no_results')
    };

    this.setup();
  }

  private setup() {
    this.loadQueries().then(collection => {
      let sortedQueries = _.reverse(_.sortBy(collection.elements, 'public'));
      let autocompleteValues = _.map(sortedQueries, query => { return { label: query.name, query: query }; } );

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
        return this.$scope.i18n.scope_global;
      } else {
        return this.$scope.i18n.scope_private;
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
    this.contextMenu.close();
  }

  private setLoaded() {
    this.$scope.loaded = true;
    this.$scope.i18n.loading = '';
  }
}
