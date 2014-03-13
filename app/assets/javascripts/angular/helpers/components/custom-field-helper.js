angular.module('openproject.uiComponents')

.constant('CUSTOM_FIELD_PREFIX', 'cf_')
.service('CustomFieldHelper', ['CUSTOM_FIELD_PREFIX', function(CUSTOM_FIELD_PREFIX) {
  return {
    isCustomFieldKey: function(key) {
      return key.substr(0, CUSTOM_FIELD_PREFIX.length) === CUSTOM_FIELD_PREFIX;
    },
    getCustomFieldId: function(cfKey) {
      return parseInt(cfKey.substr(CUSTOM_FIELD_PREFIX.length, 10), 10);
    }
  };
}]);
