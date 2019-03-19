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
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";
import {take} from "rxjs/operators";

@Component({
  selector: 'wp-list',
  templateUrl: './wp.list.component.html'
})
export class WorkPackagesListComponent extends WorkPackagesViewBase implements OnDestroy {
  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  /** Whether the title can be edited */
  titleEditingEnabled:boolean;

  /** Current query title to render */
  selectedTitle?:string;
  currentQuery:QueryResource;

  /** Whether we're saving the query */
  querySaving:boolean;

  /** Listener callbacks */
  unRegisterTitleListener:Function;
  removeTransitionSubscription:Function;

  /** Determine when query is initially loaded */
  tableInformationLoaded = false;

  /** Project identifier of the list */
  projectIdentifier = this.$state.params['projectPath'] || null;

  private readonly titleService:OpTitleService = this.injector.get(OpTitleService);

  ngOnInit() {
    super.ngOnInit();

    // Load query initially
    this.wpTableRefresh.clear('Impending query loading.');
    this.loadCurrentQuery();

    // Load query on URL transitions
    this.updateQueryOnParamsChanges();

    // Mark tableInformationLoaded when initially loading done
    this.setupInformationLoadedListener();

    // Update title on entering this state
    this.unRegisterTitleListener = this.$transitions.onSuccess({to: 'work-packages.list'}, () => {
      if (this.selectedTitle) {
        this.titleService.setFirstPart(this.selectedTitle);
      }
    });

    // Update the title whenever the query changes
    this.querySpace.query.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      this.updateTitle(query);
      this.currentQuery = query;
    });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.unRegisterTitleListener();
    this.removeTransitionSubscription();
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

  public updateQueryName(val:string) {
    this.querySaving = true;
    this.currentQuery.name = val;
    this.wpListService.save(this.currentQuery)
      .then(() => this.querySaving = false)
      .catch(() => this.querySaving = false);
  }


  updateTitle(query:QueryResource) {
    if (query.persisted) {
      this.selectedTitle = query.name;
      this.titleEditingEnabled = this.authorisationService.can('query', 'updateImmediately');
    } else {
      this.selectedTitle =  this.wpStaticQueries.getStaticName(query);
      this.titleEditingEnabled = false;
    }

    // Update the title if we're in the list state alone
    if (this.$state.current.name === 'work-packages.list') {
      this.titleService.setFirstPart(this.selectedTitle);
    }
  }

  public refresh(visibly:boolean = false, firstPage:boolean = false):Promise<unknown> {
    let promise:Promise<unknown>;

    if (firstPage) {
      promise = this.wpListService.loadCurrentResultsListFirstPage();
    } else {
      promise = this.wpListService.reloadCurrentResultsList();
    }

    if (visibly) {
      this.loadingIndicator = promise;
    }

    return promise;
  }

  protected updateQueryOnParamsChanges() {
    // Listen for param changes
    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      let options = transition.options();

      // Avoid performing any changes when we're going to reload
      if (options.reload || (options.custom && options.custom.notify === false)) {
        return true;
      }

      const params = transition.params('to');
      let newChecksum = this.wpListService.getCurrentQueryProps(params);
      let newId:string = params.query_id ? params.query_id.toString() : null;

      this.wpListChecksumService
        .executeIfOutdated(newId,
          newChecksum,
          () => this.loadCurrentQuery());
    });
  }

  protected setupInformationLoadedListener() {
    this.querySpace.tableRendering.onQueryUpdated
      .values$()
      .pipe(
        take(1)
      )
      .subscribe(() => this.tableInformationLoaded = true);
  }

  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.table.promise = promise;
  }

  protected loadCurrentQuery():Promise<unknown> {
    return this.loadingIndicator =
      this.wpListService
        .loadCurrentQueryFromParams(this.projectIdentifier)
        .then(() => this.querySpace.rendered.valuesPromise());
  }
}
