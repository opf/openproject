angular.module('openproject.uiComponents')

  .filter('historicalDateKind', function() {
    return function(object, dateOption) {
      if (!object.does_historical_differ()) return;

      var newDate = object[dateOption];
      var oldDate = object.historical()[dateOption];

      if (oldDate && newDate) {
        return (newDate < oldDate ? 'postponed' : 'preponed');
      }
      return "changed";
    };
  })

  // timelines
  .filter('getOptionColumn', function() {
    var map = {
      "type": "getTypeName",
      "status": "getStatusName",
      "responsible": "getResponsibleName",
      "assigned_to": "getAssignedName",
      "project": "getProjectName"
    };

    return function(object, option) {
      switch(option) {
        case 'start_date':
          return object.start_date;
        case 'due_date':
          return object.due_date;
        default:
          return object[map[option]]();
      }
    };
  });

// TODO integrate custom field columns as can be seen in the example provided by the code copied from ui.js
// ...
// function booleanCustomFieldValue(value) {
//   if (value) {
//     if (value === "1") {
//       return timeline.i18n("general_text_Yes")
//     } else if (value === "0") {
//       return timeline.i18n("general_text_No")
//     }
//   }
// }

// function formatCustomFieldValue(value, custom_field_id) {
//   switch(timeline.custom_fields[custom_field_id].field_format) {
//     case "bool":
//       return booleanCustomFieldValue(value);
//     case "user":
//       if (timeline.users[value])
//         return timeline.users[value].name;
//     default:
//       return value;
//   }
// }

// function getCustomFieldValue(data, custom_field_name) {
//   var custom_field_id = parseInt(custom_field_name.substr(3), 10), value = data[custom_field_name];

//   if (value) {
//     return jQuery('<span class="tl-column">' + timeline.escape(formatCustomFieldValue(value, custom_field_id)) + '</span>');
//   }
// }

// var timeline = this;
// return {
//   all: ['due_date', 'type', 'status', 'responsible', 'start_date'],
//   general: function (data, val) {
//     if (val.substr(0, 3) === "cf_") {
//       return getCustomFieldValue(data, val);
//     }
//  ...
