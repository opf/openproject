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

describe('refresh-on-form-changes directive', function() {
  var element:any;
  var $compile;
  var $rootScope;
  var windowObj = {
    location: '/old/value',
    sessionStorage: {
      getItem: angular.noop
    },
    openProject: {
      environment: 'test'
    }
  };

  beforeEach(angular.mock.module(
    'openproject',
    'openproject.workPackages.directives'
  ));

  beforeEach(angular.mock.module(function($provide:any) {
     $provide.value('$window', windowObj);
  }));

  beforeEach(angular.mock.inject(function(_$compile_:any, _$rootScope_:any) {
    $compile = _$compile_;
    $rootScope = _$rootScope_;

    var template = `
      <form id="foobar">
      <refresh-on-form-changes url="/foo/bar" input-selector="#myval">
        <input type="hidden" name="foo" value="bar" />
        <input type="text" id="myval" name="foo2"/>
      </refresh-on-form-changes>
      </form>`;
    element = $compile(template)($rootScope);
    angular.element(document.body).append(element);
    $rootScope.$digest();
  }));

  afterEach(function() {
    element.remove();
  });

  it('should request the given url on input', function() {
    var input = element.find('#myval');
    input.val('asdf').trigger('change');

    expect(windowObj.location).to.eql('/foo/bar?foo=bar&foo2=asdf');
  });
});
