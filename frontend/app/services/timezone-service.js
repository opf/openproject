
module.exports = function(ConfigurationService, I18n) {
  var TimezoneService = {

    setupLocale: function() {
      moment.lang(I18n.locale);
    },

    parseDate: function(date) {
      var d = moment.utc(date);

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
      return moment(date, [ConfigurationService.dateFormatPresent() ? ConfigurationService.dateFormat() : 'L']).isValid()
    }
  };

  return TimezoneService;
};