// -- copyright
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
// ++

describe('wpListViewButton directive', function () {
  var $state, inplaceEditAll, scope, element, controller, button, label;

  beforeEach(angular.mock.module(
    'openproject.wpButtons', 'openproject.workPackages.services', 'openproject.templates',
    'openproject.services', 'openproject.config'));

  beforeEach(angular.mock.inject(function ($compile, $rootScope, _$state_, _inplaceEditAll_, I18n) {
    var html = '<wp-list-view-button projectIdentifier="projectIdentifier"></wp-list-view-button>';
    $state = _$state_;
    inplaceEditAll = _inplaceEditAll_;

    scope = $rootScope.$new();
    element = angular.element(html);

    var t = sinon.stub(I18n, 't');
    t.withArgs('js.button_list_view').returns('a wonderful title');
    t.withArgs('js.label_activate').returns('activate');

    $compile(element)(scope);
    scope.$digest();

    controller = element.controller('wpListViewButton');
    label = element.find('label');
    button = element.find('button');
  }));

  afterEach(function () {
    I18n.t.restore();
  });

  it("is active if the current state is 'work-packages.list'", function () {
    var is = sinon.stub($state, 'is').returns(true);
    expect(controller.isActive()).to.be.true;

    is.returns(false);
    expect(controller.isActive()).to.be.false;
  });

  it('is disabled if inplaceEditAll.state is true', function () {
    inplaceEditAll.start();
    expect(controller.isDisabled()).to.be.true;

    inplaceEditAll.stop();
    expect(controller.isDisabled()).to.be.false;
  });

  describe('openListView()', function () {
    var go;
    beforeEach(function () {
      go = sinon.stub($state, 'go');
      controller.openListView();
    });

    it("directs user to 'work-packages.list'", function () {
      var params = {
        projectIdentifier: controller.projectIdentifier
      };

      $state.params = {
        projectIdentifier: 'some-overwritten-value'
      };

      expect(go.withArgs('work-packages.list', params).calledOnce).to.be.true;
    });
  });

  describe('when active', function () {
    beforeEach(function () {
      sinon.stub(controller, 'isActive').returns(true);
      scope.$digest();
    });

    it('returns a value as the access key', function () {
      expect(label.attr('accesskey')).to.be.an('undefined');
    });

    it("has the button class set to '-active' ", function () {
      expect(button.attr('class')).to.contain('-active')
    });

    it('should have equal text values', function () {
      expect(label.text().trim()).to.eq(controller.text.label);
      expect(button.text().trim()).to.eq(controller.text.label);
      expect(button.attr('title').trim()).to.eq(controller.text.label);
    });
  });

  describe('when not active', function () {
    it('returns a value as the access key', function () {
      expect(label.attr('accesskey')).not.to.be.an('undefined');
    });

    it("should have the 'activate' prefix in the text values", function () {
      expect(label.text()).to.contain('activate');
    });
  });
});
