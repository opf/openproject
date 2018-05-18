//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

describe('remote-field-updater directive', function() {
  var element:any;
  var $compile:any;
  var $rootScope:any;
  var $httpBackend:any;

  beforeEach(angular.mock.module(
    'openproject',
    'openproject.workPackages.directives'
  ));

  beforeEach(angular.mock.inject(function(_$compile_:any, _$rootScope_:any, _$httpBackend_:any) {
    $compile = _$compile_;
    $rootScope = _$rootScope_;
    $httpBackend = _$httpBackend_;

    var template = `
      <remote-field-updater url="/foo/bar">
        <input type="text" class="remote-field--input" data-remote-field-key="q"/>
        <div class="remote-field--target"></div>
      </remote-field-updater>`;
    element = $compile(template)($rootScope);
    angular.element(document.body).append(element);
    $rootScope.$digest();
  }));

  afterEach(function() {
    element.remove();
  });

  it('should request the given url on input', function(done) {
    $httpBackend.expectGET('/foo/bar?q=foobar').respond(200, '<span>response!</span>');
    var input = element.find('.remote-field--input');
    var e = jQuery.Event('keyup');
    e.keyCode = 65;
    input.val('foobar').trigger(e);

    setTimeout(() => {
    $httpBackend.flush();

    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();

    expect(element.find('.remote-field--target span').length).to.eql(1);
    done();
    }, 1500);
  });
});
