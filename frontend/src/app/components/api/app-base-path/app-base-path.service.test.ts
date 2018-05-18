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
import IDocumentService = angular.IDocumentService;

describe('appBasePath service', () => {
  var $document:IDocumentService;
  var appBasePath:string;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_$document_:any, _appBasePath_:any) {
    [$document, appBasePath] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(appBasePath).to.exist;
  });

  describe('when there is no meta tag', () => {
    it('should be an empty string', () => {
      expect(appBasePath).to.equal('');
    });
  });

  describe('when the meta tag is present', () => {
    var metaTag:HTMLElement;

    before(() => {
      metaTag = document.createElement('meta');

      metaTag.setAttribute('name', 'app_base_path');
      metaTag.setAttribute('content', 'my_path');

      document.head.appendChild(metaTag);
    });

    after(() => {
      document.head.removeChild(metaTag);
    });

    it('should get the app base path from the app_base_path meta tag', () => {
      expect(appBasePath).to.equal('my_path');
    });

    describe('when the path has a trailing slash', () => {
      before(() => {
        jQuery('meta[name="app_base_path"]')
          .attr('content', '/base/my_path/');
      });

      it('should remove trailing slashes from the appBasePath', () => {
        expect(appBasePath).to.equal('/base/my_path');
      });
    });
  });
});
