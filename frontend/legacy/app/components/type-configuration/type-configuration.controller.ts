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

import {openprojectLegacyModule} from "core-app/openproject-legacy-app";

const autoScroll:any = require('dom-autoscroller');

function typesFormConfigurationCtrl(
  dragulaService:any,
  $scope:any,
  $element:any,
  $window:ng.IWindowService,
  $compile:any) {

  let confirmDialog:any;
  let NotificationsService:any;
  let externalRelationQueryConfiguration:any;
  let I18n:any;

  window.OpenProject.getPluginContext().then((context) => {
    confirmDialog = context.services.confirmDialog;
    NotificationsService = context.services.notifications;
    externalRelationQueryConfiguration = context.services.externalRelationQueryConfiguration;
    I18n = context.services.i18n;
  });

  // Hook on form submit
  const form = jQuery('#types-form-configuration').closest('form');
  form.on('submit.typeformupdater', () => {
    return !$scope.updateHiddenFields();
  });

  $scope.showNotificationWhileDragging

  // Setup autoscroll
  autoScroll(
    [
      document.getElementById('content-wrapper')
    ],
    {
    margin: 20,
    maxSpeed: 5,
    scrollWhenOutside: true,
    autoScroll: function(this:any) {
      const groups = dragulaService.find($scope, 'groups').drake;
      const attributes = dragulaService.find($scope, 'attributes').drake;
      return this.down && (groups.dragging || attributes.dragging);
    }
  });

  dragulaService.options($scope, 'groups', {
    moves: function(el:any, container:any, handle:any) {
      const editing = angular.element(el).find('.group-edit-in-place--input').length > 0;
      return !editing && handle.classList.contains('group-handle');
    }
  });

  dragulaService.options($scope, 'attributes', {
    moves: function(el:any, container:any, handle:any) {
      return handle.classList.contains('attribute-handle');
    }
  });

  $scope.resetToDefault = ($event:JQueryEventObject):boolean => {
    confirmDialog
      .confirm({
        text: {
          title: I18n.t('js.types.attribute_groups.reset_title'),
          text: I18n.t('js.types.attribute_groups.confirm_reset'),
          button_continue: I18n.t('js.label_reset')
        }
      }).then(() => {
      angular.element('input#type_attribute_groups').first().val(JSON.stringify([]));

      // Disable our form handler that updates the attribute groups
      form.off('submit.typeformupdater');
      form.submit();
    })
      .catch(() => undefined /* Cancelled */);

    $event.preventDefault();
    return false;
  };

  $scope.deactivateAttribute = ($event:any) => {
    angular.element($event.target)
      .parents('.type-form-conf-attribute')
      .appendTo('#type-form-conf-inactive-group .attributes');
    $scope.updateHiddenFields();
  };

  $scope.deleteGroup = ($event:any):void => {
    let group:JQuery = angular.element($event.target).parents('.type-form-conf-group');
    let attributes:JQuery = angular.element('.attributes', group).children();
    let inactiveAttributes:JQuery = angular.element('#type-form-conf-inactive-group .attributes');

    inactiveAttributes.prepend(attributes);

    group.remove();
    $scope.updateHiddenFields();
  };


  $scope.createGroup = (templateSelector:string, groupName?:string):JQuery => {
    let newGroup:JQuery = angular.element(templateSelector).clone();
    let draggableGroups:JQuery = angular.element('#draggable-groups');
    let randomId:string = Math.ceil(Math.random() * 10000000).toString();

    // Remove the id of the template:
    newGroup.attr('id', null);
    // Every group needs a key and an original-key:
    newGroup.attr('data-key', randomId);
    newGroup.attr('data-original-key', randomId);

    let groupEditInPlace:JQuery = angular.element('group-edit-in-place', newGroup);

    if (groupName) {
      groupEditInPlace.attr('name', groupName);
    }

    groupEditInPlace.attr('key', randomId);

    draggableGroups.prepend(newGroup);
    $compile(newGroup)($scope);
    return newGroup;
  };

  $scope.addGroupAndOpenQuery = ():void => {
    let newGroup = $scope.addQuery();
    $scope.editQuery(undefined, newGroup);
  };

  $scope.addGroup = ():JQuery => {
    return $scope.createGroup('#type-form-conf-group-template');
  };

  $scope.addQuery = ():JQuery => {
    return $scope.createGroup('#type-form-conf-query-template');
  };

  $scope.editQuery = (event:JQueryEventObject, group?:JQuery) => {
    let originator:JQuery;
    if (group) {
      originator = group.find('.type-form-query');
    } else {
      originator = jQuery(event.target).closest('.type-form-query') as JQuery;
    }
    const currentQuery = $scope.extractQuery(originator);

    // Disable display mode and timeline for now since we don't want users to enable it
    const disabledTabs = {
      'display-settings': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
      'timelines': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled')
    };

    externalRelationQueryConfiguration.show(
      currentQuery,
      (queryProps:any) => originator.data('queryProps', queryProps),
      disabledTabs
    );
  };

  $scope.extractQuery = (originator:JQuery) => {
    // When the query has never been edited, the query props are stringified in the query dataset
    let persistentQuery = originator.data('query');
    // When the user edited the query at least once, the up-to-date query is persisted in queryProps dataset
    let currentQuery = originator.data('queryProps');

    return currentQuery || persistentQuery || undefined;
  };

  $scope.updateHiddenFields = ():boolean => {
    let groups:HTMLElement[] = angular.element('.type-form-conf-group').not('#type-form-conf-group-template').toArray();
    let seenGroupNames:{ [name:string]:boolean } = {};
    let newAttrGroups:Array<Array<(string | Array<string> | boolean)>> = [];
    let inputAttributeGroups:JQuery;
    let hasError = false;

    // Clean up previous error states
    NotificationsService.clear();

    // Extract new grouping from DOM structure, starting
    // with the active groups.
    groups.forEach((groupEl:HTMLElement) => {
      let group:JQuery = jQuery(groupEl);
      let groupKey:string = group.attr('data-key') as string;
      let keyIsSymbol:boolean = JSON.parse(group.attr('data-key-is-symbol') as string);
      let attrKeys:string[] = [];

      angular.element(group).removeClass('-error');
      if (groupKey == null || groupKey.length === 0) {
        // Do not save groups without a name.
        return;
      }

      if (seenGroupNames[groupKey.toLowerCase()]) {
        NotificationsService.addError(
          I18n.t('js.types.attribute_groups.error_duplicate_group_name', {group: groupKey})
        );
        angular.element(group).addClass('-error');
        hasError = true;
        return;
      }

      seenGroupNames[groupKey.toLowerCase()] = true;

      // For query groups, serialize the changed query, if any
      if (group.hasClass('type-form-query-group')) {
        const originator = group.find('.type-form-query');
        const queryProps = $scope.extractQuery(originator);

        newAttrGroups.push([groupKey, queryProps]);
        return;
      }


      // For attribute groups, extract the attributes
      group.find('.type-form-conf-attribute').each((i, attribute) => {
        let attr:JQuery = jQuery(attribute);
        let key:string = attr.attr('data-key') as string;
        attrKeys.push(key);
      });

      newAttrGroups.push([groupKey, attrKeys, keyIsSymbol]);
    });

    // Finally update hidden input fields
    inputAttributeGroups = angular.element('input#type_attribute_groups').first();

    inputAttributeGroups.val(JSON.stringify(newAttrGroups));

    return hasError;
  };

  $scope.groupNameChange = function(key:string, newValue:string):void {
    jQuery(`.type-form-conf-group[data-original-key="${key}"]`)
      .attr('data-key', newValue)
      .attr('data-key-is-symbol', "false");
    $scope.updateHiddenFields();
  };

  $scope.showEEOnlyHint = function(evt:JQueryEventObject):void {
    confirmDialog.confirm({
      text: {
        title: I18n.t('js.types.attribute_groups.upgrade_to_ee'),
        text: I18n.t('js.types.attribute_groups.upgrade_to_ee_text'),
        button_continue: I18n.t('js.types.attribute_groups.more_information'),
        button_cancel: I18n.t('js.types.attribute_groups.nevermind')
      }
    }).then(() => {
      window.location.href = $scope.upsaleLink;
    })
      .catch(() => undefined /* Not confirmed */);
  };
}

openprojectLegacyModule.controller('TypesFormConfigurationCtrl', typesFormConfigurationCtrl);
