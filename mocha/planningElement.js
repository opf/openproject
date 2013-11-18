function nop() {}

var modalHelperInstance = {
  setupTimeline: nop
};

Timeline.completeUI = nop;
Timeline.setupUI = nop;

var possibleData = {
  projects: [{"id":1,"name":"Eltern","identifier":"eltern-1","description":"","project_type_id":null,"parent_id":null,"responsible_id":null,"type_ids":[1,2,3,4,5,6],"created_on":"2013-11-04T14:49:36Z","updated_on":"2013-11-04T14:49:36Z"}]
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

Array.prototype.clone =   function clone() {
  return Array.prototype.slice.call(this, 0);
};

describe('Timeline', function () {
  it('should create a timeline object', function () {
    Timeline.startup({
      project_id: 1
    });
  });
});

describe('Planning Element', function(){
  before(function(){
    this.pe = planningElementFactory.create({
      "start_date": "2012-11-11",
      "due_date": "2012-11-10"
    });
    this.pe2 = planningElementFactory.create();
  });

  describe('start() and end()', function(){
    it('should return date object', function(){
      expect(this.pe.start()).to.be.an.instanceof(Date);
      expect(this.pe.end()).to.be.an.instanceof(Date);
    });

    it('should return correct date', function () {
      expect(this.pe.start().getTime()).to.equal(1352588400*1000);
      expect(this.pe.end().getTime()).to.equal(1352502000*1000);
    });

    it('should have no historical', function () {
      expect(this.pe.has_historical()).to.be.false;
    });

    it('should return undefined for no date' , function () {
      expect(this.pe2.start()).to.not.exist;
      expect(this.pe2.end()).to.not.exist;
    });
  });
});