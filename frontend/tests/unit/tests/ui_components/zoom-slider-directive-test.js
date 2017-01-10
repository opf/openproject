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

describe('zoomSlider Directive', function() {
  var I18n, compile, element, scope;

  beforeEach(angular.mock.module('openproject.uiComponents'));
  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile, _I18n_) {
    var html = '<zoom-slider scales="scales" selected-scale="scale"></zoom-slider>';

    element = angular.element(html);
    scope = $rootScope.$new();
    scope.scales = ['yearly', 'quarterly', 'monthly', 'weekly', 'daily'];

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };

    I18n = _I18n_;
    sinon.stub(I18n, 't').returns('Zoom Test');
  }));

  afterEach(function() {
    I18n.t.restore();
  });

  describe('label element', function() {
    beforeEach(function() {
      compile();
    });

    it('provides an accessible label for the slider', function() {
      var slider = element.find('input[type="range"]');
      var label = element.find('label[for=' + slider.attr('id') + ']');

      expect(label.text().trim()).to.equal('Zoom Test');
    });
  });

  describe('slider element', function() {
    var slider;

    beforeEach(function() {
      compile();
      slider = element.find('input[type="range"]');
    });

    it('has an initial value set', function() {
      expect(slider.val()).to.eq('1');
    });

    it('has its value set based on selectedScale', function() {
      scope.scale = 'monthly';
      scope.$apply();
      expect(slider.val()).to.eq('3');
    });

    it('updates selectedScale when its value changes', function() {
      slider.val('2').change();
      expect(scope.scale).to.eq('quarterly');

      slider.val('5').change();
      expect(scope.scale).to.eq('daily');
    });
  });
});
