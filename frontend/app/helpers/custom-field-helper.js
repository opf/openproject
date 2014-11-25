//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module.exports = function(CUSTOM_FIELD_PREFIX, I18n) {

  var CustomFieldHelper = {
    isCustomFieldKey: function(key) {
      return key.substr(0, CUSTOM_FIELD_PREFIX.length) === CUSTOM_FIELD_PREFIX;
    },
    getCustomFieldId: function(cfKey) {
      return parseInt(cfKey.substr(CUSTOM_FIELD_PREFIX.length, 10), 10);
    },
    booleanCustomFieldValue: function(value) {
      if (value) {
        return value === '0' ? I18n.t('js.general_text_No') : I18n.t('js.general_text_Yes');
      }
    },
    parseNumeric: function(value, parseMethod){
      if(value && ((typeof(value) == "string" && value.length > 0) || typeof(value) == "number") && !isNaN(value)){
        return parseMethod(value);
      }
      return '';
    },
    formatCustomFieldValue: function(value, fieldFormat, users) {
      switch(fieldFormat) {
        case 'bool':
          return CustomFieldHelper.booleanCustomFieldValue(value);
        case 'user':
          // not the nicest piece of code, but to be discarded soon
          if (users) {
            // try to look up users, assume value is an id
            if (users[value]) return users[value].name;
          } else {
            // assume value is already a user object
            if (value) return value.name;
          }
          break;
        case 'int':
          return CustomFieldHelper.parseNumeric(value, parseInt);
        case 'float':
          return CustomFieldHelper.parseNumeric(value, parseFloat);
        default:
          return value;
      }
    }
  };

  return CustomFieldHelper;
};
