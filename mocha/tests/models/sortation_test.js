/*jshint expr: true*/

describe('Sortation', function() {

  var Sortation;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Sortation_) {
    Sortation = _Sortation_;
  }));

  it('should exist', function() {
    expect(Sortation).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new Sortation()).to.exist;
    expect(new Sortation()).to.be.an('object');
  });

});
