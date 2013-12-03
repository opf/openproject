window.backbone_app.views.BaseView = Backbone.View.extend({

  /* Utils */
  i18n: function(key) {
    var value = this.options.i18n[key];
    var message;
    if (value === undefined) {
      message = 'translation missing: ' + key;
      if (console && console.log) {
        console.log(message);
      }
      return message;
    } else {
      return value;
    }
  },
});