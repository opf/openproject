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

import {opModelsModule} from '../../../../angular-modules';
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IDocumentService = angular.IDocumentService;

describe('opTooltipContainer service', () => {
  var $document: IDocumentService;
  var opTooltipContainer: IAugmentedJQuery;

  beforeEach(angular.mock.module(opModelsModule.name));
  beforeEach(angular.mock.inject(function (_$document_, _opTooltipContainer_) {
    [$document, opTooltipContainer] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(opTooltipContainer).to.exist;
  });

  it('should be a single dom element', () => {
    expect(opTooltipContainer).to.have.length(1);
  });

  it('should be appended to the document body', () => {
    expect($document.find('body .op-tooltip-container')).to.have.length.above(0);
  });
});
