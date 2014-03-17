/*jshint expr: true*/

describe('Filter', function() {

  var Filter;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Filter_) {
    Filter = _Filter_;
  }));

  it('should exist', function() {
    expect(Filter).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new Filter()).to.exist;
    expect(new Filter()).to.be.an('object');
  });

});
