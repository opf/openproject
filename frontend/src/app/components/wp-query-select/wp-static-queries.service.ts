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
import {IAutocompleteItem} from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Injectable} from '@angular/core';

@Injectable()
export class WorkPackageStaticQueriesService {
  constructor(readonly I18n:I18nService) { }

  public latestActivityQuery:IAutocompleteItem;
  public ganttQuery:IAutocompleteItem;
  public createdByMeQuery:IAutocompleteItem;
  public assignedToMeQuery:IAutocompleteItem;
  public recentlyCreatedQuery:IAutocompleteItem;
  public defaultQuery:IAutocompleteItem;
  public summary:IAutocompleteItem;

  public text = {
    assignee: this.I18n.t('js.work_packages.properties.assignee'),
    author: this.I18n.t('js.work_packages.properties.author'),
    created_at: this.I18n.t('js.work_packages.properties.createdAt'),
    updated_at: this.I18n.t('js.work_packages.properties.updatedAt'),
    status: this.I18n.t('js.work_packages.properties.status'),
    work_packages: this.I18n.t('js.label_work_package_plural'),
    gantt: this.I18n.t('js.timelines.gantt_chart'),
    latest_activity: this.I18n.t('js.work_packages.default_queries.latest_activity'),
    created_by_me:this.I18n.t('js.work_packages.default_queries.created_by_me'),
    assigned_to_me: this.I18n.t('js.work_packages.default_queries.assigned_to_me'),
    recently_created: this.I18n.t('js.work_packages.default_queries.recently_created'),
    all_open: this.I18n.t('js.work_packages.default_queries.all_open'),
    summary: this.I18n.t('js.work_packages.default_queries.summary')
  };

  // Create all static queries manually
  // The query_props configure default values of column names, sorting and applied filters
  // All queries are sorted by their update or creation time (so the latest is always the first)
  public get all() {
    this.latestActivityQuery = {
      query: null,
      label: this.text.latest_activity,
      query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],' +
                    '"t":"updatedAt:desc,parent:asc",' +
                    '"f":[{"n":"status","o":"o","v":[]},{"n":"updatedAt","o":"w","v":[]}]}'
    };
    this.ganttQuery = {
      query: null,
      label: this.text.gantt,
      query_props: '%7B%22tv%22%3Atrue%7D'
    };
    this.createdByMeQuery = {
      query: null,
      label: this.text.created_by_me,
      query_props: '{"c":["id","subject","type","status","assignee","updatedAt"],' +
                    '"t":"updatedAt:desc,parent:asc",' +
                    '"f":[{"n":"status","o":"o","v":[]},{"n":"author","o":"=","v":["me"]}]}'
    };
    this.assignedToMeQuery = {
      query: null,
      label: this.text.assigned_to_me,
      query_props: '{"c":["id","subject","type","status", "author", "updatedAt"],' +
                    '"t":"updatedAt:desc,parent:asc",' +
                    '"f":[{"n":"status","o":"o","v":[]},{"n":"assignee","o":"=","v":["me"]}]}'
    };
    this.recentlyCreatedQuery = {
      query: null,
      label: this.text.recently_created,
      query_props: '{"c":["id","subject","type","status","assignee","createdAt"],' +
                    '"t":"createdAt:desc,parent:asc",' +
                    '"f":[{"n":"status","o":"o","v":[]},{"n":"createdAt","o":"w","v":[]}]}'
    };
    this.defaultQuery = {
      query: null,
      label: this.text.all_open,
      query_props: '{"c":["id","subject","type","status","assignee","version","updatedAt"],' +
                    '"t":"updatedAt:desc,parent:asc"}'
    };
    this.summary = {
      query: null,
      label: this.text.summary,
      query_props: ''
    };

    return [this.latestActivityQuery,
            this.ganttQuery,
            this.createdByMeQuery,
            this.assignedToMeQuery,
            this.recentlyCreatedQuery,
            this.defaultQuery,
            this.summary];
  }

  public nameFor(query:QueryResource) {
    let filters:string[] = [];
    _.each(query.filters, filter => {
      filters.push(filter.name);
    });

    if (query.timelineVisible) {
      return this.text.gantt;
    } else if (filters.length === 2 && filters.includes(this.text.updated_at)) {
      return this.text.latest_activity;
    } else if (filters.length === 2 && filters.includes(this.text.author)) {
      return this.text.created_by_me;
    } else if (filters.length === 2 && filters.includes(this.text.assignee)) {
      return this.text.assigned_to_me;
    } else if (filters.length === 2 && filters.includes(this.text.created_at)) {
      return this.text.recently_created;
    } else if (filters.length === 1 && filters.includes(this.text.status)) {
      return this.text.all_open;
    } else return this.text.work_packages;
  }
}
