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

var expect = chai.expect;

describe('requestForConfirmation directive', () => {
  var scope:any, element:any, controller:any, body:any;
  beforeEach(angular.mock.module('openproject', 'openproject.uiComponents'));

  beforeEach(angular.mock.inject(($compile:any, $rootScope:any) => {
    var html = `
      <form class="request-for-confirmation">
        <input type="text" id="somevalue" />
      </form>
    `;

    element = angular.element(html);

    scope = $rootScope.$new();
    body = angular.element(document.body);

    $compile(element)(scope);
    body.append(element);
    scope.$digest();

    controller = element.controller('requestForConfirmation');
  }));

  it('should call the dialog when submitting', () => {
    sinon.spy(controller, 'openConfirmationDialog');
    element.trigger('submit');
    expect(controller.openConfirmationDialog).to.have.been.called;
  });

  afterEach(() => {
    element.remove();
    body.remove('.ngdialog-theme-openproject');
  });
});
