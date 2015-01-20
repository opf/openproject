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

describe('selectableTitle Directive', function() {
  var MODEL_SELECTOR = 'div.dropdown-scrollable a';
  var compile, element, rootScope, scope, $timeout;
  beforeEach(module(
    'openproject.workPackages',
    'openproject.workPackages.controllers',
    'openproject.templates',
    'truncate'));

  beforeEach(inject(function($rootScope, $compile, _$timeout_) {
    var html;
    $timeout = _$timeout_;
    html = '<selectable-title selected-title="selectedTitle" reload-method="reloadMethod" groups="groups"></selectable-title>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    scope.doNotShow = true;

    compile = function() {
      angular.element(document).find('body').append(element);
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  afterEach(function() {
    element.remove();
  });

  describe('element', function() {
    beforeEach(function() {
      scope.selectedTitle = 'Title1';
      scope.reloadMethod = function(){ return false; };
      scope.transitionMethod = function(){ return false; };
      scope.groups = [{
        name: 'pinkies',
        models: [
          ['pinky1', 1],
          ['pinky2', 2]
        ]
      }, {
        name: 'perkies',
        models: [
          ['perky1', 4],
          ['perky2', 5],
          ['Misunderstood anthropomorphic puppet pig', 6],
          ['Badly misunderstood anthropomorphic puppet pig', 6]
        ]
      }];

      compile();

      element.find('span:first').click();
      scope.$digest();
    });

    it('should compile to a div', function() {
      expect(element.prop('tagName')).to.equal('DIV');
    });

    it('should show the title', function() {
      var content = element.find('h2').first();
      expect(content.text().trim()).to.equal('Title1');
    });

    it('should show a title (tooltip) for the title', function() {
      var content = element.find('h2').first();
      expect(content.attr('title')).to.equal('Title1');
    });

    it('should show all group titles', function() {
      var headers = element.find('.title-group-header');
      expect(headers.length).to.equal(2);
      expect(jQuery(headers[0]).text()).to.equal('pinkies');
      expect(jQuery(headers[1]).text()).to.equal('perkies');
    });

    it('should show text for models', function() {
      var models = element.find(MODEL_SELECTOR);
      expect(jQuery(models[0]).text()).to.equal('pinky1');
      expect(jQuery(models[1]).text()).to.equal('pinky2');
      expect(jQuery(models[2]).text()).to.equal('perky1');
      expect(jQuery(models[3]).text()).to.equal('perky2');
    });

    it('should truncate long text for models', function() {
      var models = element.find(MODEL_SELECTOR);
      expect(jQuery(models[4]).text()).to.equal('Misunderstood anthropomorphic puppet pig');
      expect(jQuery(models[5]).text()).to.equal('Badly misunderstood anthropomorphic pupp...');
    });

    it('should show a title (tooltip) for models', function() {
      var models = element.find(MODEL_SELECTOR);
      expect(models.length).to.equal(6);
      expect(jQuery(models[0]).attr('title')).to.equal('pinky1');
      expect(jQuery(models[1]).attr('title')).to.equal('pinky2');
      expect(jQuery(models[2]).attr('title')).to.equal('perky1');
      expect(jQuery(models[3]).attr('title')).to.equal('perky2');
    });

    it('should not truncate long titles (tooltips) for models', function() {
      var models = element.find(MODEL_SELECTOR);
      expect(jQuery(models[4]).attr('title')).to.equal('Misunderstood anthropomorphic puppet pig');
      expect(jQuery(models[5]).attr('title')).to.equal('Badly misunderstood anthropomorphic puppet pig');
    });

    xit('should change the title when a model is clicked on', function() {
      var title = element.find('span').first();
      expect(title.text()).to.equal('Title1');

      element.find('a').first().click();
      expect(title.text()).to.equal('pinky1');
    });

    it('highlight the first element on key down pressed', function() {
      var title = element.find('span').first();
      expect(title.text().replace(/(\n|\s)/gm,"")).to.equal('Title1');

      var listElements = element.find('li');

      expect(jQuery(listElements[0]).hasClass('selected')).to.be.false;

      var e = jQuery.Event('keydown');
      e.which = 40;
      element.find('input').first().trigger(e);
      expect(jQuery(listElements[0]).hasClass('selected')).to.be.true;
    });

    it('highlight the second element on key down/up pressing group transitioning bonanza', function() {
      var title = element.find('span').first();
      expect(title.text().replace(/(\n|\s)/gm,"")).to.equal('Title1');

      var listElements = element.find('li');

      expect(jQuery(listElements[1]).hasClass('selected')).to.be.false;

      for(var i = 0; i < 3; i++){
        var e = jQuery.Event('keydown');
        e.which = 40;
        element.find('#title-filter').first().trigger(e);
      }
      var e = jQuery.Event('keydown');
      e.which = 38;
      element.find('#title-filter').first().trigger(e);

      expect(jQuery(listElements[1]).hasClass('selected')).to.be.true;
    });

    xit('should change the title when a model is selected with enter key', function() {
      var title = element.find('span').first();
      expect(title.text()).to.equal('Title1');

      var listElements = element.find('li');
      var e = jQuery.Event('keydown');
      e.which = 40;
      element.find('#title-filter').first().trigger(e);

      var e = jQuery.Event('keydown');
      e.which = 13;
      element.find('#title-filter').first().trigger(e);

      expect(title.text()).to.equal('pinky1');
    });
  });
});
