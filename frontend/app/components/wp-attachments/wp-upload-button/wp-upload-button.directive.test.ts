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

import {opApiModule} from '../../../angular-modules';
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IProvideService = angular.auto.IProvideService;
import I18n = op.I18n;

describe('wpUploadButton directive', () => {
  var workPackage;

  var I18n;
  var compile;
  var scope;

  var element: IAugmentedJQuery;
  var button: any;

  var uploadsDirectiveScope;

  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(angular.mock.module(opApiModule.name, ($provide: IProvideService) => {
    $provide.decorator('wpAttachmentsUploadDirective', () => {
      return {
        scope: {
          workPackage: '='
        }
      };
    });
  }));

  beforeEach(angular.mock.inject(function ($rootScope, $compile, _I18n_) {
    I18n = _I18n_;
    const html = '<wp-upload-button template="wp-upload-button-toolbar" work-package="workPackage"></wp-upload-button>';
    workPackage = {};
    scope = $rootScope.$new();
    scope.workPackage = workPackage;

    sinon.stub(I18n, 't').returns('add attachments');

    compile = () => {
      element = $compile(html)(scope);
      scope.$digest();

      button = element.find('.button');
      uploadsDirectiveScope = button.scope();
    };

    compile();
  }));

  afterEach(function() {
    I18n.t.restore();
  });

  it('should have the add attachment tooltip', () => {
    expect(button.attr('title')).to.equal('add attachments');
  });

  it('should pass the work package to the upload directive', () => {
    expect(uploadsDirectiveScope.workPackage).to.equal(workPackage);
  });

  it('should have the attachment icon as icon', () => {
    expect(button.find('.icon-attachment')).to.have.length(1);
  });
});
