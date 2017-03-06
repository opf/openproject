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

function typesFormConfigurationCtrl(dragulaService:any, $scope:any) {
  dragulaService.options($scope, 'groups', {
    moves: function (el:any, container:any, handle:any) {
      return handle.className === 'group-handle';
    }
  });

  dragulaService.options($scope, 'attributes', {
    moves: function (el:any, container:any, handle:any) {
      return handle.className === 'attribute-handle';
    }
  });

  $scope.updateHiddenFields = (): void => {
    let groups: HTMLElement[] = angular.element('.type-form-conf-group').not('#type-form-conf-group-template').toArray();
    let newAttrGroups: Array<Array<(string | Array<string>)>> = [];
    let newAttrVisibility: any = {};
    let inputAttributeGroups: JQuery;
    let inputAttributeVisibility: JQuery;

    // Extract new grouping and visibility setup from DOM structure, starting
    // with the active groups.
    groups.forEach((group:HTMLElement) => {
      let groupKey: string = angular.element(group).data('key');
      let attributes: HTMLElement[] = angular.element('.type-form-conf-attribute', group).toArray();
      let attrKeys: string[] = [];

      attributes.forEach((attribute:HTMLElement) => {
        let attr: JQuery = angular.element(attribute)
        let key: string = attr.data('key')
        attrKeys.push(key);
        newAttrVisibility[key] = 'default';
        if (angular.element('input[type=checkbox]', attr)) {
          let checkbox: any = angular.element('input[type=checkbox]', attr)[0];
          if (checkbox.checked) {
            console.log(key, "is visible");
            newAttrVisibility[key] = 'visible';
          }
        }
      });

      if (attrKeys.length > 0) {
        newAttrGroups.push([groupKey, attrKeys]);
      }
    });

    // Then get visibility states for inactive attributes.
    let inactiveAttributes: HTMLElement[] = angular.element('#type-form-conf-inactive-group .type-form-conf-attribute').toArray();
    inactiveAttributes.forEach((attr: HTMLElement) => {
      let key: string = angular.element(attr).data('key');
      newAttrVisibility[key] = 'hidden';
    });

    // Finally update hidden input fields
    inputAttributeGroups = angular.element('input#type_attribute_groups').first();
    inputAttributeVisibility = angular.element('input#type_attribute_visibility').first();

    inputAttributeGroups.val(JSON.stringify(newAttrGroups));
    inputAttributeVisibility.val(JSON.stringify(newAttrVisibility));
  };

  $scope.$on('groups.drop', function (e:any, el:any) {
    $scope.updateHiddenFields();
  });
  $scope.$on('attributes.drop', function (e:any, el:any) {
    $scope.updateHiddenFields();
  });
};

openprojectModule.controller('TypesFormConfigurationCtrl', typesFormConfigurationCtrl);
