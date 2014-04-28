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

/*jshint expr: true*/

describe('FilterService', function() {

  var FilterService;

  // mock dependency
  beforeEach(module('openproject.workPackages.config', function($provide) {
    $provide.constant('OPERATORS_AND_LABELS_BY_FILTER_TYPE', {
      theFilterType: [['=', 'any_label'], ['!', 'label_not_equals']]
    });
  }));

  beforeEach(module('openproject.services'));
  beforeEach(inject(function(_FilterService_) {
    FilterService = _FilterService_;
  }));

  describe('#getOperatorsAndTranslatedLabelsByFilterType', function () {
    var I18n, t;

    beforeEach(inject(function(_I18n_){
      I18n = _I18n_;
      t = sinon.stub(I18n, 't');
      t.withArgs('js.any_label').returns('translated label');
    }));

    afterEach(inject(function() {
      I18n.t.restore();
    }));


    it('translates the labels', function() {
      expect(FilterService.getOperatorsAndTranslatedLabelsByFilterType()['theFilterType'][0][1]).to.equal('translated label');
    });

  });

});
