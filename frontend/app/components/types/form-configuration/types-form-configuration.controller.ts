import { ConfirmDialogService } from './../../modals/confirm-dialog/confirm-dialog.service';
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

import {openprojectModule} from '../../../angular-modules';
const autoScroll:any = require('dom-autoscroller');

function typesFormConfigurationCtrl(
  dragulaService:any,
  NotificationsService:any,
  I18n:op.I18n,
  $scope:any,
  $element:any,
  confirmDialog:ConfirmDialogService,
  $window:ng.IWindowService,
  $compile:any) {

  // Setup autoscroll
  var scroll = autoScroll(window, {
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
    moves: function (el:any, container:any, handle:any) {
      const editing = angular.element(el).find('.group-edit-in-place--input').length > 0;
      return !editing && handle.classList.contains('group-handle');
    }
  });

  dragulaService.options($scope, 'attributes', {
    moves: function (el:any, container:any, handle:any) {
      return handle.classList.contains('attribute-handle');
    }
  });

  $scope.resetToDefault = ($event:any):void => {
    confirmDialog.confirm({
      text: {
        title: I18n.t('js.types.attribute_groups.reset_title'),
        text: I18n.t('js.types.attribute_groups.confirm_reset'),
        button_continue: I18n.t('js.label_reset')
      }
    }).then(() => {
      let form:JQuery = angular.element($event.target).parents('form');
      angular.element('input#type_attribute_groups').first().val(JSON.stringify([]));
      angular.element('input#type_attribute_visibility').first().val(JSON.stringify({}));
      form.submit();
    });
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

    if (attributes.length > 0) {
      angular.forEach(attributes, function(attribute:HTMLElement) {
        // reset visibility
        let checkbox:HTMLInputElement = angular.element('input[type=checkbox]', attribute)[0] as HTMLInputElement;
        checkbox.checked = false;
      });
    }

    inactiveAttributes.prepend(attributes);

    group.remove();
    $scope.updateHiddenFields();
  };

  $scope.addGroup = (event:any) => {
    let newGroup:JQuery = angular.element('#type-form-conf-group-template').clone();
    let draggableGroups:JQuery = angular.element('#draggable-groups');
    let randomId:string = Math.ceil(Math.random() * 10000000).toString();

    // Remove the id of the template:
    newGroup.attr('id', null);
    // Every group needs a key and an original-key:
    newGroup.attr('data-key', randomId);
    newGroup.attr('data-original-key', randomId);
    angular.element('group-edit-in-place', newGroup).attr('key', randomId);

    draggableGroups.prepend(newGroup);
    $compile(newGroup)($scope);
  };

  $scope.updateHiddenFields = ():void => {
    let groups:HTMLElement[] = angular.element('.type-form-conf-group').not('#type-form-conf-group-template').toArray();
    let seenGroupNames:{[name:string]:boolean} = {};
    let newAttrGroups:Array<Array<(string | Array<string> | boolean)>> = [];
    let newAttrVisibility:any = {};
    let inputAttributeGroups:JQuery;
    let inputAttributeVisibility:JQuery;

    // Clean up previous error states
    NotificationsService.clear();

    // Extract new grouping and visibility setup from DOM structure, starting
    // with the active groups.
    groups.forEach((group:HTMLElement) => {
      let groupKey:string = angular.element(group).attr('data-key');
      let keyIsSymbol:boolean = JSON.parse(angular.element(group).attr('data-key-is-symbol'));
      let attributes:HTMLElement[] = angular.element('.type-form-conf-attribute', group).toArray();
      let attrKeys:string[] = [];

      angular.element(group).removeClass('-error');
      if (groupKey == null || groupKey.length === 0) {
        // Do not save groups without a name.
        return;
      }

      if (seenGroupNames[groupKey]) {
        NotificationsService.addError(
          I18n.t('js.types.attribute_groups.error_duplicate_group_name', { group: groupKey })
        );
        angular.element(group).addClass('-error');
        return;
      }

      seenGroupNames[groupKey] = true;
      attributes.forEach((attribute:HTMLElement) => {
        let attr:JQuery = angular.element(attribute);
        let key:string = attr.attr('data-key');
        attrKeys.push(key);
        newAttrVisibility[key] = 'default';
        if (angular.element('input[type=checkbox]', attr)) {
          let checkbox:HTMLInputElement = angular.element('input[type=checkbox]', attr)[0] as HTMLInputElement;
          if (checkbox.checked) {
            newAttrVisibility[key] = 'visible';
          }
        }
      });

      newAttrGroups.push([groupKey, attrKeys, keyIsSymbol]);
    });


    // Then get visibility states for inactive attributes.
    let inactiveAttributes:HTMLElement[] = angular.element('#type-form-conf-inactive-group .type-form-conf-attribute').toArray();
    inactiveAttributes.forEach((attr:HTMLElement) => {
      let key:string = angular.element(attr).attr('data-key');
      newAttrVisibility[key] = 'hidden';
    });

    // Finally update hidden input fields
    inputAttributeGroups = angular.element('input#type_attribute_groups').first();
    inputAttributeVisibility = angular.element('input#type_attribute_visibility').first();

    inputAttributeGroups.val(JSON.stringify(newAttrGroups));
    inputAttributeVisibility.val(JSON.stringify(newAttrVisibility));
  };

  $scope.groupNameChange = function(key:string, newValue:string):void {
    angular.element(`.type-form-conf-group[data-original-key="${key}"]`).attr('data-key', newValue).attr('data-key-is-symbol', "false");
    $scope.updateHiddenFields();
  };

  $scope.$on('groups.drop', function (e:any, el:any) {
    $scope.updateHiddenFields();
  });
  $scope.$on('attributes.drop', function (e:any, el:any) {
    $scope.updateHiddenFields();
  });

  $scope.showEEOnlyHint = function():void {
    confirmDialog.confirm({
      text: {
        title: I18n.t('js.types.attribute_groups.upgrade_to_ee'),
        text: I18n.t('js.types.attribute_groups.upgrade_to_ee_text'),
        button_continue: I18n.t('js.types.attribute_groups.more_information'),
        button_cancel: I18n.t('js.types.attribute_groups.nevermind')
      }
    }).then(() => {
      window.location.href = $scope.upsaleLink;
    });
  }
};

openprojectModule.controller('TypesFormConfigurationCtrl', typesFormConfigurationCtrl);
