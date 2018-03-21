//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
import {WorkPackageResourceInterface} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableTimelineService} from "../../wp-fast-table/state/wp-table-timeline.service";
import {Inject, Injectable} from "@angular/core";
import {PathHelperService} from "core-components/common/path-helper/path-helper.service";
import PathHelper = op.PathHelper;
import {HookServiceToken, UrlParamsHelperToken} from "core-app/angular4-transition-utils";

export type WorkPackageAction = {
  text:string;
  icon?:string;
  link:string;
  href?:string;
}

@Injectable()
export class WorkPackageContextMenuHelperService {

  private BULK_ACTIONS = [
    {
      text: I18n.t('js.work_packages.bulk_actions.edit'),
      icon: 'edit',
      link: 'update',
      href: this.PathHelper.staticBase + '/work_packages/bulk/edit'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.move'),
      icon: 'move',
      link: 'move',
      href: this.PathHelper.staticBase + '/work_packages/move/new'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.copy'),
      icon: 'copy',
      link: 'copy',
      href: this.PathHelper.staticBase + '/work_packages/move/new?copy=true'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.delete'),
      icon: 'delete',
      link: 'delete',
      href: this.PathHelper.staticBase + '/work_packages/bulk?_method=delete'
    }
  ];

  constructor(@Inject(HookServiceToken) private HookService:any,
              @Inject(UrlParamsHelperToken) private UrlParamsHelper:any,
              private wpTableTimeline:WorkPackageTableTimelineService,
              private PathHelper:PathHelperService) {
  }

  public getPermittedActionLinks(workPackage:WorkPackageResourceInterface, permittedActionConstants:any):WorkPackageAction[] {
    var singularPermittedActions:any[] = [];

    var allowedActions = this.getAllowedActions(workPackage, permittedActionConstants);

    angular.forEach(allowedActions, function(allowedAction) {
      singularPermittedActions.push({
        icon: allowedAction.icon,
        text: allowedAction.text,
        link: workPackage[allowedAction.link].href
      });
    });

    return singularPermittedActions;
  }

  public getIntersectOfPermittedActions(workPackages:any) {
    var bulkPermittedActions:any = [];

    var permittedActions = _.filter(this.BULK_ACTIONS, (action:any) => {
      return _.every(workPackages, (workPackage:WorkPackageResourceInterface) => {
        return this.getAllowedActions(workPackage, [action]).length >= 1;
      });
    });

    angular.forEach(permittedActions, (permittedAction:any) => {
      bulkPermittedActions.push({
        icon: permittedAction.icon,
        text: permittedAction.text,
        link: this.getBulkActionLink(permittedAction, workPackages)
      });
    });

    return bulkPermittedActions;
  }

  public getBulkActionLink(action:any, workPackages:any) {
    var workPackageIdParams = {
      'ids[]': workPackages.map(function(wp:any){
        return wp.id;
      })
    };
    var serializedIdParams = this.UrlParamsHelper.buildQueryString(workPackageIdParams);

    var linkAndQueryString = action.href.split('?');
    var link = linkAndQueryString.shift();
    var queryParts = linkAndQueryString.concat(new Array(serializedIdParams));

    return link + '?' + queryParts.join('&');
  }

  public getAllowedActions(workPackage:WorkPackageResourceInterface, actions:any):WorkPackageAction[] {
    var allowedActions:any[] = [];

    angular.forEach(actions, (action) => {
      if (workPackage.hasOwnProperty(action.link)) {
        action.text = action.text || I18n.t('js.button_' + action.icon);
        allowedActions.push(action);
      }
    });

    angular.forEach(this.HookService.call('workPackageTableContextMenu'), (action) => {
      if (workPackage.hasOwnProperty(action.link)) {
        var index = action.indexBy ? action.indexBy(allowedActions) : allowedActions.length;
        allowedActions.splice(index, 0, action)
      }
    });

    if (workPackage.addRelation && this.wpTableTimeline.isVisible) {
      allowedActions.push({
        icon: "relation-precedes",
        text: I18n.t("js.relation_buttons.add_predecessor"),
        link: "addRelation"
      });
      allowedActions.push({
        icon: "relation-follows",
        text: I18n.t("js.relation_buttons.add_follower"),
        link: "addRelation"
      });
    }

    if (!!workPackage.addChild) {
      allowedActions.push({
        icon: "relation-new-child",
        text: I18n.t("js.relation_buttons.add_new_child"),
        link: "addChild"
      });
    }

    return allowedActions;
  }

  public getPermittedActions(workPackages:WorkPackageResourceInterface[], permittedActionConstants:any):WorkPackageAction[] {
    if (workPackages.length === 1) {
      return this.getPermittedActionLinks(workPackages[0], permittedActionConstants);
    } else {
      return this.getIntersectOfPermittedActions(workPackages);
    }
  }
}
