// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Injectable } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { StateService } from '@uirouter/core';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { IOpSidemenuItem } from 'core-app/shared/components/sidemenu/sidemenu.component';
import { ViewType } from 'core-app/shared/components/op-view-select/op-view-select.component';

interface IStaticQuery extends IOpSidemenuItem {
  view:ViewType;
}

@Injectable()
export class StaticQueriesService {
  private staticQueries:IStaticQuery[] = [];

  constructor(private readonly I18n:I18nService,
    private readonly $state:StateService,
    private readonly CurrentProject:CurrentProjectService,
    private readonly PathHelper:PathHelperService,
    private readonly CurrentUser:CurrentUserService) {
    this.staticQueries = this.buildQueries();
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
    create_new_team_planner: this.I18n.t('js.team_planner.create_new'),
  };

  public getStaticName(query:QueryResource):string {
    if (this.$state.params.query_props) {
      const queryProps = JSON.parse(this.$state.params.query_props) as { pa:unknown, pp:unknown }&unknown;
      delete queryProps.pp;
      delete queryProps.pa;
      const queryPropsString = JSON.stringify(queryProps);

      const matched = this.staticQueries.find((item) => {
        const uiParams = item.uiParams as { query_id:string, query_props:string };
        return uiParams && uiParams.query_props === queryPropsString;
      });

      if (matched) {
        return matched.title;
      }
    }

    // Try to detect the all open filter
    if (query.filters.length === 1 // Only one filter
      && query.filters[0].id === 'status' // that is status
      && query.filters[0].operator.id === 'o') { // and is open
      return this.text.all_open;
    }

    // Otherwise, fall back to work packages
    return this.text.work_packages;
  }

  public buildQueries():IStaticQuery[] {
    let items:IStaticQuery[] = [
      {
        title: this.text.all_open,
        uiSref: 'work-packages',
        uiParams: { query_id: '', query_props: '' },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.latest_activity,
        uiSref: 'work-packages',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc","f":[{"n":"status","o":"o","v":[]}]}',
        },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.recently_created,
        uiSref: 'work-packages',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","type","status","assignee","createdAt"],"hi":false,"g":"","t":"createdAt:desc","f":[{"n":"status","o":"o","v":[]}]}',
        },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.gantt,
        uiSref: 'work-packages',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","type","subject","status","startDate","dueDate"],"tv":true,"tzl":"auto","tll":"{\\"left\\":\\"startDate\\",\\"right\\":\\"dueDate\\",\\"farRight\\":\\"subject\\"}","hi":true,"g":"","t":"startDate:asc","f":[{"n":"status","o":"o","v":[]}]}',
        },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.all_open,
        uiSref: 'bim.partitioned.list',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","bcfThumbnail","type","status","assignee","updatedAt"],"t":"id:desc"}',
        },
        view: 'Bim',
      },
      {
        title: this.text.latest_activity,
        uiSref: 'bim.partitioned.list',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","bcfThumbnail","type","status","assignee","updatedAt"],"t":"updatedAt:desc","f":[{"n":"status","o":"o","v":[]}]}',
        },
        view: 'Bim',
      },
      {
        title: this.text.recently_created,
        uiSref: 'bim.partitioned.list',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","bcfThumbnail","type","status","assignee","createdAt"],"t":"createdAt:desc","f":[{"n":"status","o":"o","v":[]}]}',
        },
        view: 'Bim',
      },
    ];

    const projectIdentifier = this.CurrentProject.identifier;
    if (projectIdentifier) {
      items = [
        ...items,
        ...this.projectDependentQueries(projectIdentifier),
      ];
    }

    if (this.CurrentUser.isLoggedIn) {
      items = [
        ...items,
        ...this.userDependentQueries(),
      ];
    }

    return items;
  }

  public getStaticQueriesForView(view:ViewType):IOpSidemenuItem[] {
    return this.staticQueries
      .filter((query) => query.view === view);
  }

  public getCreateNewQueryForView(view:ViewType):IOpSidemenuItem[] {
    return this.buildCreateNewQuery()
      .filter((query) => query.view === view);
  }

  private buildCreateNewQuery():IStaticQuery[] {
    return [{
      title: this.text.create_new_team_planner,
      uiSref: 'team_planner.page.show',
      uiParams: {
        query_id: '',
        query_props: '',
      },
      view: 'TeamPlanner',
    }];
  }

  private projectDependentQueries(projectIdentifier:string):IStaticQuery[] {
    return [
      {
        title: this.text.summary,
        href: `${this.PathHelper.projectWorkPackagesPath(projectIdentifier)}/report`,
        view: 'WorkPackagesTable',
      },
    ];
  }

  private userDependentQueries():IStaticQuery[] {
    return [
      {
        title: this.text.created_by_me,
        uiSref: 'work-packages',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc,id:asc","f":[{"n":"status","o":"o","v":[]},{"n":"author","o":"=","v":["me"]}]}',
        },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.assigned_to_me,
        uiSref: 'work-packages',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","type","status","author","updatedAt"],"hi":false,"g":"","t":"updatedAt:desc,id:asc","f":[{"n":"status","o":"o","v":[]},{"n":"assigneeOrGroup","o":"=","v":["me"]}]}',
        },
        view: 'WorkPackagesTable',
      },
      {
        title: this.text.created_by_me,
        uiSref: 'bim.partitioned.list',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","bcfThumbnail","type","status","assignee","updatedAt"],"t":"id:desc","f":[{"n":"status","o":"o","v":[]},{"n":"author","o":"=","v":["me"]}]}',
        },
        view: 'Bim',
      },
      {
        title: this.text.assigned_to_me,
        uiSref: 'bim.partitioned.list',
        uiParams: {
          query_id: '',
          query_props: '{"c":["id","subject","bcfThumbnail","type","status","author","updatedAt"],"t":"id:desc","f":[{"n":"status","o":"o","v":[]},{"n":"assigneeOrGroup","o":"=","v":["me"]}]}',
        },
        view: 'Bim',
      },
    ];
  }
}
