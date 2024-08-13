//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Directive, ElementRef, Injector, Input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import {
  OpContextMenuTrigger,
} from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  WpTableConfigurationModalComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  selectableTitleIdentifier,
  triggerEditingEvent,
} from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';
import { QuerySharingModalComponent } from 'core-app/shared/components/modals/share-modal/query-sharing.modal';
import {
  QueryGetIcalUrlModalComponent,
} from 'core-app/shared/components/modals/get-ical-url-modal/query-get-ical-url.modal';
import { SaveQueryModalComponent } from 'core-app/shared/components/modals/save-modal/save-query.modal';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import isPersistedResource from 'core-app/features/hal/helpers/is-persisted-resource';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import {
  QueryRequestParams,
  UrlParamsHelperService,
} from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

@Directive({
  selector: '[opSettingsContextMenu]',
})
export class OpSettingsMenuDirective extends OpContextMenuTrigger {
  @Input('opSettingsContextMenu-query') public query:QueryResource;

  @Input() public hideTableOptions:boolean;

  @Input() public showCalendarSharingOption:boolean;

  private form:QueryFormResource;

  private loadingPromise:PromiseLike<any>;

  constructor(
    readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly opModalService:OpModalService,
    readonly wpListService:WorkPackagesListService,
    readonly authorisationService:AuthorisationService,
    readonly states:States,
    readonly injector:Injector,
    readonly querySpace:IsolatedQuerySpace,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly urlParamsHelper:UrlParamsHelperService,
    readonly opStaticQueries:StaticQueriesService,
    readonly turboRequests:TurboRequestsService,
    readonly I18n:I18nService,
  ) {
    super(elementRef, opContextMenu);
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    this.querySpace.query.values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((queryUpdate) => {
        this.query = queryUpdate;
      });

    this.loadingPromise = this.querySpace.queryForm.valuesPromise();

    this.querySpace.queryForm.values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((formUpdate) => {
        this.form = formUpdate;
      });
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.loadingPromise.then(() => {
      this.buildItems();
      this.opContextMenu.show(this, evt);
    });
  }

  public get locals() {
    return {
      contextMenuId: 'settingsDropdown',
      items: this.items,
    };
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    const additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom',
    };

    const position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  public onClose(focus:boolean) {
    if (focus) {
      this.afterFocusOn.focus();
    }
  }

  private allowQueryAction(event:JQuery.TriggeredEvent, action:any) {
    return this.allowAction(event, 'query', action);
  }

  private allowWorkPackageAction(event:JQuery.TriggeredEvent, action:any) {
    return this.allowAction(event, 'work_packages', action);
  }

  private allowFormAction(event:JQuery.TriggeredEvent, action:string) {
    if (this.form.$links[action]) {
      return true;
    }
    event.stopPropagation();
    return false;
  }

  private allowAction(event:JQuery.TriggeredEvent, modelName:string, action:any) {
    if (this.authorisationService.can(modelName, action)) {
      return true;
    }
    event.stopPropagation();
    return false;
  }

  private buildExportDialogHref(query:QueryResource):string {
    const params:Partial<QueryRequestParams>&{ title:string } = this.urlParamsHelper
      .buildV3GetQueryFromQueryResource(query) as Partial<QueryRequestParams>&{ title:string };
    params['columns[]'] = this.wpTableColumns.getColumns().map((column) => column.id);
    params.title = this.queryTitle(query);
    const queryString = this.urlParamsHelper.buildQueryString(params) || '';
    const url = new URL(window.location.href);
    url.pathname = `${url.pathname}/export_dialog`;
    url.search = queryString;
    return url.toString();
  }

  private queryTitle(query:QueryResource):string {
    return isPersistedResource(query) ? query.name : this.staticQueryName(query);
  }

  protected staticQueryName(query:QueryResource):string {
    return this.opStaticQueries.getStaticName(query);
  }

  private buildItems() {
    this.items = [
      {
        // Configuration modal
        disabled: false,
        linkText: this.I18n.t('js.toolbar.settings.configure_view'),
        hidden: this.hideTableOptions,
        icon: 'icon-settings',
        onClick: ($event:JQuery.TriggeredEvent) => {
          this.opContextMenu.close();
          this.opModalService.show(WpTableConfigurationModalComponent, this.injector);

          return true;
        },
      },
      {
        // Insert columns
        linkText: this.I18n.t('js.work_packages.query.insert_columns'),
        hidden: this.hideTableOptions,
        icon: 'icon-columns',
        class: 'hidden-for-mobile',
        onClick: () => {
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'columns' },
          );
          return true;
        },
      },
      {
        // Sort by
        linkText: this.I18n.t('js.toolbar.settings.sort_by'),
        hidden: this.hideTableOptions,
        icon: 'icon-sort-by',
        onClick: () => {
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'sort-by' },
          );
          return true;
        },
      },
      {
        // Group by
        linkText: this.I18n.t('js.toolbar.settings.group_by'),
        hidden: this.hideTableOptions,
        icon: 'icon-group-by',
        class: 'hidden-for-mobile',
        onClick: () => {
          this.opModalService.show<WpTableConfigurationModalComponent>(
            WpTableConfigurationModalComponent,
            this.injector,
            { initialTab: 'display-settings' },
          );
          return true;
        },
      },
      {
        // Rename query shortcut
        disabled: !this.query.id || this.authorisationService.cannot('query', 'updateImmediately'),
        linkText: this.I18n.t('js.toolbar.settings.page_settings'),
        icon: 'icon-edit',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.allowQueryAction($event, 'update')) {
            jQuery(`${selectableTitleIdentifier}`).trigger(triggerEditingEvent);
          }

          return true;
        },
      },
      {
        // Query save modal
        disabled: this.authorisationService.cannot('query', 'updateImmediately'),
        linkText: this.I18n.t('js.toolbar.settings.save'),
        icon: 'icon-save',
        onClick: ($event:JQuery.TriggeredEvent) => {
          const { query } = this;
          if (!isPersistedResource(query) && this.allowQueryAction($event, 'updateImmediately')) {
            this.opModalService.show(SaveQueryModalComponent, this.injector);
          } else if (query.id && this.allowQueryAction($event, 'updateImmediately')) {
            this.wpListService.save(query);
          }

          return true;
        },
      },
      {
        // Query save as modal
        disabled: this.form ? !this.form.$links.create_new : this.authorisationService.cannot('query', 'updateImmediately'),
        linkText: this.I18n.t('js.toolbar.settings.save_as'),
        icon: 'icon-save',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.allowFormAction($event, 'create_new')) {
            this.opModalService.show(SaveQueryModalComponent, this.injector);
          }

          return true;
        },
      },
      {
        // Delete query
        disabled: this.authorisationService.cannot('query', 'delete'),
        linkText: this.I18n.t('js.toolbar.settings.delete'),
        icon: 'icon-delete',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.allowQueryAction($event, 'delete')
            && window.confirm(this.I18n.t('js.text_query_destroy_confirmation'))) {
            this.wpListService.delete();
          }

          return true;
        },
      },
      {
        // Calendar sharing modal
        hidden: !this.showCalendarSharingOption,
        disabled: this.authorisationService.cannot('query', 'icalUrl'),
        linkText: this.I18n.t('js.toolbar.settings.share_calendar'),
        icon: 'icon-link', // TODO: find sharing icons
        onClick: () => {
          if (this.authorisationService.can('query', 'icalUrl')) {
            this.opModalService.show(QueryGetIcalUrlModalComponent, this.injector);
          }

          return true;
        },
      },
      {
        // Export query
        disabled: this.authorisationService.cannot('work_packages', 'representations'),
        linkText: this.I18n.t('js.toolbar.settings.export'),
        hidden: this.hideTableOptions,
        icon: 'icon-export',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.allowWorkPackageAction($event, 'representations')) {
            const query = this.querySpace.query.value;
            if (query) {
              const href = this.buildExportDialogHref(query);
              void this.turboRequests.requestStream(href);
            }
          }
          return true;
        },
      },
      {
        // Sharing modal
        disabled: this.authorisationService.cannot('query', 'unstar') && this.authorisationService.cannot('query', 'star'),
        linkText: this.I18n.t('js.toolbar.settings.visibility_settings'),
        icon: 'icon-watched',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.allowQueryAction($event, 'unstar') || this.allowQueryAction($event, 'star')) {
            this.opModalService.show(QuerySharingModalComponent, this.injector);
          }

          return true;
        },
      },
      {
        divider: true,
        hidden: !(this.query.results.customFields && this.form.configureForm),
      },
      {
        // Settings modal
        hidden: !this.query.results.customFields || this.hideTableOptions,
        href: this.query.results.customFields && this.query.results.customFields.href,
        linkText: this.query.results.customFields && this.query.results.customFields.name,
        icon: 'icon-custom-fields',
        onClick: () => false,
      },
    ];
  }
}
