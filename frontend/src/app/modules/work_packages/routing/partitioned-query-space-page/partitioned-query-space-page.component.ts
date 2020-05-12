// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {ChangeDetectionStrategy, Component, OnDestroy, OnInit} from "@angular/core";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";
import {take} from "rxjs/operators";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {ComponentType} from "@angular/cdk/overlay";
import {Ng2StateDeclaration} from "@uirouter/angular";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageFilterContainerComponent} from "core-components/filters/filter-container/filter-container.directive";

export interface DynamicComponentDefinition {
  component:ComponentType<any>;
  inputs?:{ [inputName:string]:any };
  outputs?:{ [outputName:string]:Function };
}

export interface ToolbarButtonComponentDefinition extends DynamicComponentDefinition {
  containerClasses?:string;
  show?:() => boolean;
}

export type ViewPartitionState = '-split'|'-left-only'|'-right-only';

@Component({
  selector: 'partitioned-query-space-page',
  templateUrl: './partitioned-query-space-page.component.html',
  styleUrls: ['./partitioned-query-space-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    /** We need to provide the wpNotification service here to get correct save notifications for WP resources */
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    QueryParamListenerService
  ]
})
export class PartitionedQuerySpacePageComponent extends WorkPackagesViewBase implements OnInit, OnDestroy {
  @InjectField() I18n:I18nService;
  @InjectField() titleService:OpTitleService;
  @InjectField() queryParamListener:QueryParamListenerService;

  text:{ [key:string]:string } = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
  };

  /** Whether the title can be edited */
  titleEditingEnabled:boolean;

  /** Current query title to render */
  selectedTitle?:string;
  currentQuery:QueryResource|undefined;

  /** Whether we're saving the query */
  toolbarDisabled:boolean;

  /** Do we currently have query props ? */
  showToolbarSaveButton:boolean;

  /** Listener callbacks */
  unRegisterTitleListener:Function;
  removeTransitionSubscription:Function;

  /** Determine when query is initially loaded */
  showToolbar = false;

  /** The toolbar buttons to render */
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [];

  /** Whether filtering is allowed */
  filterAllowed:boolean = true;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** What route (if any) should we go back to using the back button left of the title? */
  backButtonCallback:Function|undefined;

  /** Which filter container component to mount */
  filterContainerDefinition:DynamicComponentDefinition = {
    component: WorkPackageFilterContainerComponent
  };

  ngOnInit() {
    super.ngOnInit();

    this.showToolbarSaveButton = !!this.$state.params.query_props;
    this.setPartition(this.$state.current);
    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      const params = transition.params('to');
      const toState = transition.to();
      this.showToolbarSaveButton = !!params.query_props;
      this.setPartition(toState);
      this.cdRef.detectChanges();
    });

    // If the query was loaded, reload invisibly
    const isFirstLoad = !this.querySpace.initialized.hasValue();
    this.refresh(isFirstLoad, isFirstLoad);

    // Mark tableInformationLoaded when initially loading done
    this.setupInformationLoadedListener();

    // Load query on URL transitions
    this.queryParamListener
      .observe$
      .pipe(
        this.untilDestroyed()
      ).subscribe(() => {
      /** Ensure we reload the query from the changed props */
      this.currentQuery = undefined;
      this.refresh(true, true);
    });

    // Update title on entering this state
    this.unRegisterTitleListener = this.$transitions.onSuccess({}, () => {
      this.updateTitle(this.querySpace.query.value);
    });

    this.querySpace.query.values$().pipe(
      this.untilDestroyed()
    ).subscribe((query) => {
      this.onQueryUpdated(query);
    });
  }

  /**
   * We need to set the current partition to the grid to ensure
   * either side gets expanded to full width if we're not in '-split' mode.
   *
   * @param state The current or entering state
   */
  protected setPartition(state:Ng2StateDeclaration) {
    this.currentPartition = (state.data && state.data.partition) ? state.data.partition : '-split';
  }

  protected setupInformationLoadedListener() {
    this
      .querySpace
      .initialized
      .values$()
      .pipe(take(1))
      .subscribe(() => {
        this.showToolbar = true;
        this.cdRef.detectChanges();
      });
  }

  protected onQueryUpdated(query:QueryResource) {
    // Update the title whenever the query changes
    this.updateTitle(query);
    this.currentQuery = query;

    this.cdRef.detectChanges();
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.unRegisterTitleListener();
    this.removeTransitionSubscription();
    this.queryParamListener.removeQueryChangeListener();
  }

  public changeChangesFromTitle(val:string) {
    if (this.currentQuery && this.currentQuery.persisted) {
      this.updateTitleName(val);
    } else {
      this.wpListService
        .create(this.currentQuery!, val)
        .then(() => this.toolbarDisabled = false)
        .catch(() => this.toolbarDisabled = false);
    }
  }

  updateTitleName(val:string) {
    this.toolbarDisabled = true;
    this.currentQuery!.name = val;
    this.wpListService.save(this.currentQuery)
      .then(() => this.toolbarDisabled = false)
      .catch(() => this.toolbarDisabled = false);
  }

  updateTitle(query?:QueryResource) {

    // Too early for loaded query
    if (!query) {
      return;
    }


    if (query.persisted) {
      this.selectedTitle = query.name;
    } else {
      this.selectedTitle = this.wpStaticQueries.getStaticName(query);
    }

    this.titleEditingEnabled = this.authorisationService.can('query', 'updateImmediately');

    // Update the title if we're in the list state alone
    if (this.shouldUpdateHtmlTitle()) {
      this.titleService.setFirstPart(this.selectedTitle);
    }
  }

  refresh(visibly:boolean = false, firstPage:boolean = false):Promise<unknown> {
    let promise:Promise<unknown>;

    if (firstPage) {
      promise = this.loadFirstPage();
    } else {
      promise = this.wpListService.reloadCurrentResultsList();
    }

    if (visibly) {
      this.loadingIndicator = promise.then(() => {
        return this.additionalLoadingTime();
      });
    }

    return promise;
  }

  protected loadFirstPage():Promise<QueryResource> {
    if (this.currentQuery) {
      return this.wpListService.reloadQuery(this.currentQuery, this.projectIdentifier).toPromise();
    } else {
      return this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);
    }
  }

  protected additionalLoadingTime():Promise<unknown> {
    return Promise.resolve();
  }

  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.table.promise = promise;
  }

  protected shouldUpdateHtmlTitle():boolean {
    return true;
  }
}
