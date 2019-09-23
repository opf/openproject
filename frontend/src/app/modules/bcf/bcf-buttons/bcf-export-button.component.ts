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

import {Component, OnDestroy, OnInit, Query} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {BcfPathHelperService} from "core-app/modules/bcf/helper/bcf-path-helper.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {StateService} from "@uirouter/core";
import {WorkPackageStaticQueriesService} from "core-components/wp-query-select/wp-static-queries.service";

@Component({
  template: `
    <a [title]="text.export"
       class="button export-bcf-button"
       download
       [attr.href]="exportLink">
      <op-icon icon-classes="button--icon icon-export"></op-icon>
      <span class="button--text"> {{text.export}} </span>
    </a>
  `,
  selector: 'bcf-export-button',
})
export class BcfExportButtonComponent implements OnInit, OnDestroy {
  public text = {
    export: this.I18n.t('js.bcf.export')
  };
  public query:QueryResource;
  public exportLink:string;

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly bcfPathHelper:BcfPathHelperService,
              readonly querySpace:IsolatedQuerySpace,
              readonly queryUrlParamsHelper:UrlParamsHelperService,
              readonly state:StateService) {
  }

  ngOnInit() {
    this.querySpace.query
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((query) => {
        this.query = query;

        let projectIdentifier = this.currentProject.identifier;
        let filters = this.queryUrlParamsHelper.buildV3GetFilters(this.query.filters);
        this.exportLink = this.bcfPathHelper.projectExportIssuesPath(
          projectIdentifier!,
          JSON.stringify(filters)
        );
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }
}

DynamicBootstrapper.register({ selector: 'bcf-export-button', cls: BcfExportButtonComponent });
