//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {HookService} from "core-app/modules/plugins/hook-service";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {WorkPackageViewHierarchyIdentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service";
import {WorkPackageViewDisplayRepresentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";

export type WorkPackageAction = {
  text:string;
  key:string;
  icon?:string;
  indexBy?:(actions:WorkPackageAction[]) => number,
  link?:string;
  href?:string;
};

@Injectable()
export class WorkPackageContextMenuHelperService {

  private BULK_ACTIONS = [
    {
      text: I18n.t('js.work_packages.bulk_actions.edit'),
      key: 'edit',
      link: 'update',
      href: this.PathHelper.staticBase + '/work_packages/bulk/edit'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.move'),
      key: 'move',
      link: 'move',
      href: this.PathHelper.staticBase + '/work_packages/move/new'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.copy'),
      key: 'copy',
      link: 'copy',
      href: this.PathHelper.staticBase + '/work_packages/move/new?copy=true'
    },
    {
      text: I18n.t('js.work_packages.bulk_actions.delete'),
      key: 'delete',
      link: 'delete',
      href: this.PathHelper.staticBase + '/work_packages/bulk?_method=delete'
    }
  ];

  constructor(private HookService:HookService,
              private UrlParamsHelper:UrlParamsHelperService,
              private wpViewRepresentation:WorkPackageViewDisplayRepresentationService,
              private wpViewTimeline:WorkPackageViewTimelineService,
              private wpViewIndent:WorkPackageViewHierarchyIdentationService,
              private PathHelper:PathHelperService) {
  }

  public getPermittedActionLinks(workPackage:WorkPackageResource, permittedActionConstants:any, allowSplitScreenActions:boolean):WorkPackageAction[] {
    let singularPermittedActions:any[] = [];

    let allowedActions = this.getAllowedActions(workPackage, permittedActionConstants);

    allowedActions = allowedActions.concat(this.getAllowedParentActions(workPackage));

    allowedActions = allowedActions.concat(this.getAllowedRelationActions(workPackage, allowSplitScreenActions));

    _.each(allowedActions, (allowedAction) => {
      singularPermittedActions.push({
        key: allowedAction.key,
        text: allowedAction.text,
        icon: allowedAction.icon,
        link: allowedAction.link ? workPackage[allowedAction.link].href : undefined
      });
    });

    return singularPermittedActions;
  }

  public getIntersectOfPermittedActions(workPackages:any) {
    let bulkPermittedActions:any = [];

    let permittedActions = _.filter(this.BULK_ACTIONS, (action:any) => {
      return _.every(workPackages, (workPackage:WorkPackageResource) => {
        return this.getAllowedActions(workPackage, [action]).length >= 1;
      });
    });

    _.each(permittedActions, (permittedAction:any) => {
      bulkPermittedActions.push({
        key: permittedAction.key,
        text: permittedAction.text,
        link: this.getBulkActionLink(permittedAction, workPackages)
      });
    });

    return bulkPermittedActions;
  }

  public getBulkActionLink(action:any, workPackages:any) {
    let workPackageIdParams = {
      'ids[]': workPackages.map(function(wp:any) {
        return wp.id;
      })
    };
    let serializedIdParams = this.UrlParamsHelper.buildQueryString(workPackageIdParams);

    let linkAndQueryString = action.href.split('?');
    let link = linkAndQueryString.shift();
    let queryParts = linkAndQueryString.concat(new Array(serializedIdParams));

    return link + '?' + queryParts.join('&');
  }

  private getAllowedActions(workPackage:WorkPackageResource, actions:WorkPackageAction[]):WorkPackageAction[] {
    let allowedActions:WorkPackageAction[] = [];

    _.each(actions, (action) => {
      if (action.link && workPackage.hasOwnProperty(action.link)) {
        action.text = action.text || I18n.t('js.button_' + action.key);
        allowedActions.push(action);
      }
    });

    _.each(this.HookService.call('workPackageTableContextMenu'), (action) => {
      if (workPackage.hasOwnProperty(action.link)) {
        let index = action.indexBy ? action.indexBy(allowedActions) : allowedActions.length;
        allowedActions.splice(index, 0, action);
      }
    });

    return allowedActions;
  }

  private getAllowedParentActions(workPackage:WorkPackageResource) {
    let actions:WorkPackageAction[] = [];

    // Do not add these actions unless we're in the table
    if (!this.wpViewRepresentation.isList) {
      return [];
    }

    // Can only outdent this item if it has ancestors
    if (this.wpViewIndent.canOutdent(workPackage)) {
      actions.push({
        key: 'hierarchy-outdent',
        icon: 'icon-paragraph-left',
        text: I18n.t("js.relation_buttons.hierarchy_outdent")
      });
    }

    // Can only indent if not first and immediate predecessor is not the parent
    if (this.wpViewIndent.canIndent(workPackage)) {
      actions.push({
        key: 'hierarchy-indent',
        icon: 'icon-paragraph-right',
        text: I18n.t("js.relation_buttons.hierarchy_indent")
      });
    }

    return actions;
  }

  private getAllowedRelationActions(workPackage:WorkPackageResource, allowSplitScreenActions:boolean) {
    let allowedActions:WorkPackageAction[] = [];

    if (workPackage.addRelation && this.wpViewTimeline.isVisible) {
      allowedActions.push({
        key: "relation-precedes",
        text: I18n.t("js.relation_buttons.add_predecessor"),
        link: "addRelation"
      });
      allowedActions.push({
        key: "relation-follows",
        text: I18n.t("js.relation_buttons.add_follower"),
        link: "addRelation"
      });
    }

    if (!!workPackage.addChild && allowSplitScreenActions) {
      allowedActions.push({
        key: "relation-new-child",
        text: I18n.t("js.relation_buttons.add_new_child"),
        link: "addChild"
      });
    }

    return allowedActions;
  }


  public getPermittedActions(workPackages:WorkPackageResource[], permittedActionConstants:any, allowSplitScreenActions:boolean):WorkPackageAction[] {
    if (workPackages.length === 1) {
      return this.getPermittedActionLinks(workPackages[0], permittedActionConstants, allowSplitScreenActions);
    } else {
      return this.getIntersectOfPermittedActions(workPackages);
    }
  }
}
