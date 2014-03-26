/*jshint expr: true*/

describe('Timeline', function() {

  var model;

  beforeEach(module('openproject.timelines.models', 'openproject.uiComponents'));
  beforeEach(inject(function(Timeline) {
    model = Timeline
  }));

  it('should exist', function() {
    expect(model).to.exist;
  });

  it('should not create a timeline object without configuration options', function() {
    expect(function() {
      model.create()
    }).to.throw('No configuration options given');
  });

  it('should create a timeline object', function () {
    expect(model.instances).to.have.length(0);

    var timeline = model.create({
      project_id: 1
    });

    expect(model.instances).to.have.length(1);
    expect(timeline).to.be.a('object');
  });

});
