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

import {ChangeDetectionStrategy, Component, ComponentRef, HostBinding, OnDestroy, OnInit} from "@angular/core";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";
import {take} from "rxjs/operators";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {BcfDetectorService} from "core-app/modules/bcf/helper/bcf-detector.service";
import {wpDisplayCardRepresentation} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {ComponentType} from "@angular/cdk/overlay";
import {Ng2StateDeclaration} from "@uirouter/angular";

export interface ToolbarButtonComponentDefinition {
  component:ComponentType<any>;
  containerClasses?:string;
  show?:() => boolean;
  inputs?:{[inputName:string]:any};
  outputs?:{[outputName:string]:Function};
}

export type ViewPartitionState = '-split'|'-left-only'|'-right-only';

@Component({
  selector: 'partitioned-query-space-page',
  templateUrl: './partitioned-query-space-page.component.html',
  styleUrls: ['./partitioned-query-space-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    /** We need to provide the wpNotification service here to get correct save notifications for WP resources */
    {provide: HalResourceNotificationService, useClass: WorkPackageNotificationService},
    QueryParamListenerService
  ]
})
export class PartitionedQuerySpacePageComponent extends WorkPackagesViewBase implements OnInit, OnDestroy {
  @InjectField() titleService:OpTitleService;
  @InjectField() queryParamListener:QueryParamListenerService;

  text:{[key:string]:string} = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
  };

  /** Whether the title can be edited */
  titleEditingEnabled:boolean;

  /** Current query title to render */
  selectedTitle?:string;
  currentQuery:QueryResource;

  /** Whether we're saving the query */
  querySaving:boolean;

  /** Do we currently have query props ? */
  hasQueryProps:boolean;

  /** Listener callbacks */
  unRegisterTitleListener:Function;
  removeTransitionSubscription:Function;

  /** Determine when query is initially loaded */
  tableInformationLoaded = false;

  /** An overlay over the table shown for example when the filters are invalid */
  // TODO DOES NOT PROPAGATE
  showResultOverlay = false;

  /** The toolbar buttons to render */
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [];

  /** Whether filtering is allowed */
  filterAllowed:boolean = true;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  ngOnInit() {
    super.ngOnInit();

    this.hasQueryProps = !!this.$state.params.query_props;
    this.setPartition(this.$state.current);
    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      const params = transition.params('to');
      const toState = transition.to();
      this.hasQueryProps = !!params.query_props;
      this.setPartition(toState);
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
        untilComponentDestroyed(this)
      ).subscribe(() => {
        this.refresh(true, true);
      });

    // Update title on entering this state
    this.unRegisterTitleListener = this.$transitions.onSuccess( {}, () => {
      if (this.shouldUpdateHtmlTitle() && this.selectedTitle) {
        this.titleService.setFirstPart(this.selectedTitle);
      }
    });

    this.querySpace.query.values$().pipe(
      untilComponentDestroyed(this)
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
    this.currentPartition = state.data.partition || '-split';
  }

  protected setupInformationLoadedListener() {
    this
      .querySpace
      .initialized
      .values$()
      .pipe(take(1))
      .subscribe(() => {
        this.tableInformationLoaded = true;
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

  public saveQueryFromTitle(val:string) {
    if (this.currentQuery && this.currentQuery.persisted) {
      this.updateQueryName(val);
    } else {
      this.wpListService
        .create(this.currentQuery, val)
        .then(() => this.querySaving = false)
        .catch(() => this.querySaving = false);
    }
  }

  updateQueryName(val:string) {
    this.querySaving = true;
    this.currentQuery.name = val;
    this.wpListService.save(this.currentQuery)
      .then(() => this.querySaving = false)
      .catch(() => this.querySaving = false);
  }


  updateTitle(query:QueryResource) {
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
      promise = this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);
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

  protected additionalLoadingTime():Promise<unknown> {
    return Promise.resolve();
  }

  public updateResultVisibility(completed:boolean) {
    this.showResultOverlay = !completed;
  }

  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.table.promise = promise;
  }

  protected shouldUpdateHtmlTitle():boolean {
    return true;
  }
}
