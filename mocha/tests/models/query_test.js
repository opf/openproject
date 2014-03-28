/*jshint expr: true*/

describe('Query', function() {

  var Query;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Query_) {
    Query = _Query_;
  }));

  it('should exist', function() {
    expect(Query).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new Query()).to.exist;
    expect(new Query()).to.be.an('object');
  });

});
