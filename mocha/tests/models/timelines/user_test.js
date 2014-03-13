/*jshint expr: true*/

describe('User', function() {

  var model;

  beforeEach(module('openproject.timelines.models'));
  beforeEach(inject(function(User) {
    model = User;
  }));

  it('should exist', function() {
    expect(model).to.exist;
  });

});
