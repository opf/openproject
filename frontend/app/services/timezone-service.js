
module.exports = function(ConfigurationService, I18n) {
  var TimezoneService = {

    setupLocale: function() {
      moment.lang(I18n.locale);
    },

    parseDate: function(date, format) {
      var d = moment.utc(date, format);

      if (ConfigurationService.isTimezoneSet()) {
        d.local();
        d.tz(ConfigurationService.timezone());
      }

      return d;
    },

    formattedDate: function(date) {
      var format = ConfigurationService.dateFormatPresent() ? ConfigurationService.dateFormat() : 'L';
      return TimezoneService.parseDate(date).format(format);
    },

    formattedTime: function(date) {
      var format = ConfigurationService.timeFormatPresent() ? ConfigurationService.timeFormat() : 'LT';
      return TimezoneService.parseDate(date).format(format);
    },

    formattedISODate: function(date) {
      return TimezoneService.parseDate(date).format('YYYY-MM-DD');
    },

    isValid: function(date) {
      var format = ConfigurationService.dateFormatPresent() ?
                   ConfigurationService.dateFormat() : 'L';
      return moment(date, [format]).isValid();
    }
  };

  return TimezoneService;
};