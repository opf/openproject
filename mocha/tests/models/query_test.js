/*jshint expr: true*/

describe('Query', function() {

  var model;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(Query) {
    model = Query;
  }));

  it('should exist', function() {
    expect(model).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new model()).to.exist;
    expect(new model()).to.be.an('object');
  });

});
