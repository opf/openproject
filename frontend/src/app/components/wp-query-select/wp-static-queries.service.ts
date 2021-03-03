//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++
import { IAutocompleteItem } from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { Injectable } from '@angular/core';
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { StateService } from "@uirouter/core";
import { CurrentUserService } from "core-components/user/current-user.service";

@Injectable()
export class WorkPackageStaticQueriesService {
  constructor(private readonly I18n:I18nService,
              private readonly $state:StateService,
              private readonly CurrentProject:CurrentProjectService,
              private readonly PathHelper:PathHelperService,
              private readonly CurrentUserService:CurrentUserService) {
  }

  public text = {
    assignee: this.I18n.t('js.work_packages.properties.assignee'),
    author: this.I18n.t('js.work_packages.properties.author'),
    created_at: this.I18n.t('js.work_packages.properties.createdAt'),
    updated_at: this.I18n.t('js.work_packages.properties.updatedAt'),
    status: this.I18n.t('js.work_packages.properties.status'),
    work_packages: this.I18n.t('js.label_work_package_plural'),
    gantt: this.I18n.t('js.timelines.gantt_chart'),
    latest_activity: this.I18n.t('js.work_packages.default_queries.latest_activity'),
    created_by_me: this.I18n.t('js.work_packages.default_queries.created_by_me'),
    assigned_to_me: this.I18n.t('js.work_packages.default_queries.assigned_to_me'),
    recently_created: this.I18n.t('js.work_packages.default_queries.recently_created'),
    all_open: this.I18n.t('js.work_packages.default_queries.all_open'),
    summary: this.I18n.t('js.work_packages.default_queries.summary'),
  };

  // Create all static queries manually
  // The query_props configure default values of column names, sorting and applied filters
  // All queries are sorted by their update or creation time (so the latest is always the first)
  public get all():IAutocompleteItem[] {
    let items = [
      {
        identifier: 'all_open',
        label: this.text.all_open,
        query_props: null
      },
      {
        identifier: 'latest_activity',
        label: this.text.latest_activity,
        query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc","f":[{"n":"status","o":"o","v":[]}]}'
      },
      {
        identifier: 'gantt',
        label: this.text.gantt,
        query_props: `{"c":["id","type","subject","status","startDate","dueDate"],"tv":true,"tzl":"auto","tll":"{\\"left\\":\\"startDate\\",\\"right\\":\\"dueDate\\",\\"farRight\\":\\"subject\\"}","hi":true,"g":"","t":"startDate:asc","f":[{"n":"status","o":"o","v":[]}]}`
      },
      {
        identifier: 'recently_created',
        label: this.text.recently_created,
        query_props: '{"c":["id","subject","type","status","assignee","createdAt"],"hi":false,"g":"","t":"createdAt:desc","f":[{"n":"status","o":"o","v":[]}]}'
      }
    ] as IAutocompleteItem[];

    const projectIdentifier = this.CurrentProject.identifier;
    if (projectIdentifier) {
      items.push({
        identifier: 'summary',
        label: this.text.summary,
        static_link: this.PathHelper.projectWorkPackagesPath(projectIdentifier) + '/report'
      });
    }

    if (this.CurrentUserService.isLoggedIn) {
      items = items.concat([
        {
          identifier: 'created_by_me',
          label: this.text.created_by_me,
          query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc,id:asc","f":[{"n":"status","o":"o","v":[]},{"n":"author","o":"=","v":["me"]}]}'
        },
        {
          identifier: 'assigned_to_me',
          label: this.text.assigned_to_me,
          query_props: '{"c":["id","subject","type","status","author","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc,id:asc","f":[{"n":"status","o":"o","v":[]},{"n":"assigneeOrGroup","o":"=","v":["me"]}]}'
        }
      ]);
    }

    return items;
  }

  public getStaticName(query:QueryResource) {
    if (this.$state.params.query_props) {
      const queryProps = JSON.parse(this.$state.params.query_props);
      delete queryProps.pp;
      delete queryProps.pa;
      const queryPropsString = JSON.stringify(queryProps);

      const matched = this.all.find( item =>
        item.query_props && item.query_props === queryPropsString
      );

      if (matched) {
        return matched.label;
      }
    }

    // Try to detect the all open filter
    if (query.filters.length === 1 && // Only one filter
      query.filters[0].id === 'status' && // that is status
      query.filters[0].operator.id === 'o') { // and is open
      return this.text.all_open;
    }

    // Otherwise, fall back to work packages
    return this.text.work_packages;
  }
}
