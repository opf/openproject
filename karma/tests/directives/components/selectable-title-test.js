//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe('selectableTitle Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.uiComponents'));
  beforeEach(module('templates', 'truncate'));

  beforeEach(inject(function($rootScope, $compile) {
    var html;
    html = '<selectable-title selected-title="selectedTitle" reload-method="reloadMethod" groups="groups"></selectable-title>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    scope.doNotShow = true;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('element', function() {
    beforeEach(function() {
      scope.selectedTitle = 'Title1';
      scope.reloadMethod = function(){ return false; };
      scope.groups = [
        { name: 'pinkies', models: [['pinky1', 1], ['pinky2', 2]] },
        { name: 'perkies', models: [['perky1', 3], ['perky2', 4]] }
      ];

      compile();
    });

    it('should compile to a div', function() {
      expect(element.prop('tagName')).to.equal('DIV');
    });

    it('should show the title', function() {
      var content = element.find('span').first();
      expect(content.text()).to.equal('Title1');
    });

    it('should show all group titles and models', function() {
      var headers = element.find('.title-group-header');
      expect(headers.length).to.equal(2);
      expect(jQuery(headers[0]).text()).to.equal('pinkies');
      expect(jQuery(headers[1]).text()).to.equal('perkies');

      var models = element.find('a');
      expect(models.length).to.equal(4);
      expect(jQuery(models[0]).text()).to.equal('pinky1');
      expect(jQuery(models[1]).text()).to.equal('pinky2');
      expect(jQuery(models[2]).text()).to.equal('perky1');
      expect(jQuery(models[3]).text()).to.equal('perky2');
    });

    xit('should change the title when a model is clicked on', function() {
      var title = element.find('span').first();
      expect(title.text()).to.equal('Title1');

      element.find('a').first().click();
      expect(title.text()).to.equal('pinky1');
    });
  });
});
