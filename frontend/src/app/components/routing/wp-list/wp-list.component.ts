// -- copyright
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
// ++

import {Component, OnDestroy} from "@angular/core";
import {WorkPackagesSetComponent} from "core-components/routing/wp-set/wp-set.component";
import {StateService, TransitionService} from '@uirouter/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {States} from '../../states.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from '../../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableGroupByService} from '../../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTablePaginationService} from '../../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableSumService} from '../../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableTimelineService} from '../../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackagesListChecksumService} from '../../wp-list/wp-list-checksum.service';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {WorkPackageTableRefreshService} from '../../wp-table/wp-table-refresh-request.service';
import {WorkPackageTableHierarchiesService} from './../../wp-fast-table/state/wp-table-hierarchy.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {OpTitleService} from "core-components/html/op-title.service";
import {Observable} from "rxjs";

@Component({
  selector: 'wp-list',
  templateUrl: './wp.list.component.html'
})
export class WorkPackagesListComponent extends WorkPackagesSetComponent implements OnDestroy {
  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  titleEditingEnabled:boolean;
  selectedTitle?:string;
  currentQuery:QueryResource;
  unRegisterTitleListener:Function;

  private readonly titleService:OpTitleService = this.injector.get(OpTitleService);

  ngOnInit() {
    super.ngOnInit();

    // Update title on entering this state
    this.unRegisterTitleListener = this.$transitions.onSuccess({to: 'work-packages.list'}, () => {
      if (this.selectedTitle) {
        this.titleService.setFirstPart(this.selectedTitle);
      }
    });

    // Update the title whenever the query changes
    this.states.query.resource.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      this.updateTitle(query);
      this.currentQuery = query;
    });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.unRegisterTitleListener();
  }

  public setAnchorToNextElement() {
    // Skip to next when visible, otherwise skip to previous
    const selectors = '#pagination--next-link, #pagination--prev-link, #pagination-empty-text';
    const visibleLink = jQuery(selectors)
      .not(':hidden')
      .first();

    if (visibleLink.length) {
      visibleLink.focus();
    }
  }

  public allowed(model:string, permission:string) {
    return this.authorisationService.can(model, permission);
  }

  updateTitle(query:QueryResource) {
    if (query.id) {
      this.selectedTitle = query.name;
      this.titleEditingEnabled = true;
    } else {
      this.selectedTitle =  this.wpStaticQueries.getStaticName(query);
      this.titleEditingEnabled = false;
    }

    // Update the title if we're in the list state alone
    if (this.$state.current.name === 'work-packages.list') {
      this.titleService.setFirstPart(this.selectedTitle);
    }
  }

  protected loadCurrentQuery() {
    return super.loadCurrentQuery()
                .then(() => {
                  return this.tableState.rendered.valuesPromise();
                });
  }
}
