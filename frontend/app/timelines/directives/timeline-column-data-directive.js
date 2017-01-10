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

module.exports = function(WORK_PACKAGE_DATE_COLUMNS, I18n, CustomFieldHelper) {


  return {
    restrict: 'A',
    scope: {
      rowObject: '=',
      columnName: '=',
      timeline: '=',
      customFields: '='
    },
    templateUrl: '/templates/timelines/timeline_column_data.html',
    link: function(scope, element) {
      scope.isDateColumn = WORK_PACKAGE_DATE_COLUMNS.indexOf(scope.columnName) !== -1;

      if (CustomFieldHelper.isCustomFieldKey(scope.columnName)) {
        // watch custom field because they are loaded after the rows are being iterated
        scope.$watch('timeline.custom_fields', function() {
          scope.columnData = getCustomFieldColumnData(scope.rowObject, scope.columnName, scope.customFields, scope.timeline.users);
        });
      } else {
        scope.columnData = getColumnData();
      }

      setHistoricalData(scope);

      function getColumnData() {
        switch(scope.columnName) {
          case 'start_date':
            return scope.rowObject.start_date;
          case 'due_date':
            return scope.rowObject.due_date;
          default:
            return scope.rowObject.getAttribute(getAttributeAccessor(scope.columnName));
        }
      }

      function getAttributeAccessor(attr) {
        return {
          "type": "getTypeName",
          "status": "getStatusName",
          "responsible": "getResponsibleName",
          "assigned_to": "getAssignedName",
          "project": "getProjectName"
        }[attr] || attr;
      }

      function hasChanged(planningElement, attr) {
        return planningElement.does_historical_differ(getAttributeAccessor(attr));
      }

      function getCustomFieldColumnData(object, customFieldName, customFields, users) {
        if(!customFields) return; // custom_fields provides necessary meta information about the custom field column

        var customField = customFields[CustomFieldHelper.getCustomFieldId(customFieldName)];

        if (customField) {
          return CustomFieldHelper.formatCustomFieldValue(object[customFieldName], customField.field_format, users);
        }
      }

      function setHistoricalData() {
        scope.historicalDataDiffers = hasChanged(scope.rowObject, scope.columnName);

        scope.historicalDateKind = getHistoricalDateKind(scope.rowObject, scope.columnName);
        scope.labelTimelineChanged = I18n.t('js.timelines.change');

        if (scope.rowObject.historical_element) {
          scope.historicalData = scope.rowObject.historical_element.getAttribute(getAttributeAccessor(scope.columnName)) || I18n.t('js.timelines.empty');
        }
      }

      function getHistoricalDateKind(planningElement, attr) {
        if (!hasChanged(planningElement, attr)) return;

        var newDate = planningElement[attr];
        var oldDate = planningElement.historical_element[attr];

        if (oldDate && newDate) {
          return (newDate < oldDate ? 'preponed' : 'postponed');
        }
        return "changed";
      }
    }
  };
};
