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

/*jshint expr: true*/

describe('authoring Directive', function() {
    var createdOn = moment().utc().subtract('d', 1);
    var author = {id: '1', name: 'me, myself, and I'};
    var I18n, t, compile, element, scope, timezoneService;

    beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.helpers', 'ngSanitize'));
    beforeEach(module('openproject.templates', function($provide) {
      timezoneService = {};

      timezoneService.parseDatetime = sinon.stub().returns(createdOn);

      $provide.constant('TimezoneService', timezoneService);
    }));

    beforeEach(inject(function($rootScope, $compile, _I18n_) {
      var html = '<authoring created-on="createdOn" author="author"></authoring>';

      scope = $rootScope.$new();

      scope.createdOn = createdOn;
      scope.author = author;

      compile = function() {
        element = $compile(html)(scope);
        scope.$digest();
      };

      I18n = _I18n_;
      t = sinon.stub(I18n, 't').returns('Test');
    }));

    beforeEach(function() {
      compile();
    });

    afterEach(inject(function() {
      I18n.t.restore();
    }));

    describe('element', function() {
      it('should render a span', function() {
        expect(element.prop('tagName')).to.equal('SPAN');
      });

      it('should render author name', function() {
        expect(element.text()).to.equal('Test');
      });
    });

    describe('authoring arguments', function() {
      it('should pass correct information to I18n', function() {
        var args = I18n.t.args[0];
        var obj = args[1];
        var author = obj.author;
        var age = obj.age;
        var utc = moment.utc(createdOn);

        expect(args).to.include('js.label_added_time_by');
        expect(obj).to.have.property('author');
        expect(obj).to.have.property('age');
        expect(author).to.match(new RegExp(author.name));
        expect(age).to.match(new RegExp(utc.format('LLL')));
        expect(age).to.match(new RegExp(utc.fromNow()));
      });
    });
});
