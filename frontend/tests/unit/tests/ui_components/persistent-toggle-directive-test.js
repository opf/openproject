//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

/*jshint expr: true*/

describe('persistentToggle Directive', function() {
  var compile, element, scope, CacheService;
  var mockStorage = {};

  beforeEach(angular.mock.module('openproject.api'));
  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.services'));
  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile, _CacheService_) {
    var html = '<persistent-toggle identifier="test.foobar">' +
      '<a class="persistent-toggle--click-handler"></a>' +
      '<div class="persistent-toggle--notification"></div>' +
      '</persistent-toggle>';

    element = angular.element(html);
    scope = $rootScope.$new();
    CacheService = _CacheService_;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('toggle property', function() {
    var button, notification, getItemStub, setItemStub;

    beforeEach(inject(function($window) {
      compile();

      getItemStub = sinon.stub($window.localStorage, 'getItem', function(key) { return mockStorage[key] });
      setItemStub = sinon.stub($window.localStorage, 'setItem', function(key,value) { mockStorage[key] = value.toString() });

      button  = element.find('.persistent-toggle--click-handler');
      notification  = element.find('.persistent-toggle--notification');
    }));

    afterEach(function() {
      getItemStub.restore();
      setItemStub.restore();
    });

    it('shows when no value is set', function() {
      var value = CacheService.localStorage().get('test.foobar');
      expect(value).to.not.be.ok;
      expect(notification.prop('hidden')).to.be.false;
    });

    it('persists the notification status when clicked', function() {
      button.click();
      scope.$apply();

      expect(notification.prop('hidden')).to.be.true;
      var value = CacheService.localStorage().get('test.foobar');
      expect(value).to.equal(true);
    });
  });
});
