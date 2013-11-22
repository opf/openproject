function nop() {}

var modalHelperInstance = {
  setupTimeline: nop
};

Timeline.completeUI = nop;
Timeline.setupUI = nop;

var Raphael = {};

var possibleData = {
  projects: [{ 
      "id":1,
      "name":"Eltern",
      "identifier":"eltern-1",
      "description":"",
      "project_type_id":null,
      "parent_id":null,
      "responsible_id":null,
      "type_ids":[1,2,3,4,5,6],
      "created_on":"2013-11-04T14:49:36Z",
      "updated_on":"2013-11-04T14:49:36Z"
    }]
};

Timeline.TimelineLoader.QueueingLoader.prototype.loadElement = function (identifier, element) {
  this.loading[identifier] = element;

  var that = this;

  window.setTimeout(function () {
      var readFrom = element.context.readFrom || element.context.storeIn  || identifier;

      var data = {};
      data[readFrom] = possibleData[readFrom] || [];

      delete that.loading[identifier];

      jQuery(that).trigger('success', {
        identifier : identifier,
        context    : element.context,
        data       : data
      });

      that.onComplete();
     }
  );
};

jQuery.fn.slider = {};