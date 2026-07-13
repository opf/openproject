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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnDestroy, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfPathHelperService } from 'core-app/features/bim/bcf/helper/bcf-path-helper.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { StateService } from '@uirouter/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { JobStatusModalService } from 'core-app/features/job-status/job-status-modal.service';

@Component({
  template: `
    <a [title]="text.export_hover"
       class="button export-bcf-button"
       [attr.href]="exportLink"
       (click)="showDelayedExport($event)">
      <op-icon icon-classes="button--icon icon-export" />
      <span class="button--text"> {{text.export}} </span>
    </a>
  `,
  selector: 'bcf-export-button',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class BcfExportButtonComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  readonly I18n = inject(I18nService);
  readonly currentProject = inject(CurrentProjectService);
  readonly bcfPathHelper = inject(BcfPathHelperService);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly queryUrlParamsHelper = inject(UrlParamsHelperService);
  readonly jobStatusModalService = inject(JobStatusModalService);
  readonly httpClient = inject(HttpClient);
  readonly injector = inject(Injector);
  readonly toastService = inject(ToastService);
  readonly state = inject(StateService);
  readonly cdRef = inject(ChangeDetectorRef);

  public text = {
    export: this.I18n.t('js.bcf.export'),
    export_hover: this.I18n.t('js.bcf.export_bcf_xml_file'),
  };

  public query:QueryResource;

  public exportLink:string;

  ngOnInit() {
    this.querySpace.query
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((query) => {
        this.query = query;

        const projectIdentifier = this.currentProject.identifier;
        const filters = this.queryUrlParamsHelper.buildV3GetFilters(this.query.filters);
        this.exportLink = this.bcfPathHelper.projectExportIssuesPath(
          projectIdentifier!,
          JSON.stringify(filters),
        );
        this.cdRef.markForCheck();
      });
  }

  public showDelayedExport(event:any) {
    this.requestExport(this.exportLink);

    event.preventDefault();
  }

  private requestExport(url:string):void {
    this
      .httpClient
      .get(url, { observe: 'body', responseType: 'json' })
      .subscribe(
        (json:{ job_id:string }) => this.jobStatusModalService.show(json.job_id),
        (error:HttpErrorResponse) => this.handleError(error),
      );
  }

  private handleError(error:HttpErrorResponse) {
    this.toastService.addError(error.message || this.I18n.t('js.error.internal'));
  }
}
