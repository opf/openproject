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

import {opApiModule} from '../../../../angular-modules';
import {HalResourceTypesService} from './hal-resource-types.service';

const expect = chai.expect;

describe('halResourceTypes service', () => {
  var halResourceTypes:HalResourceTypesService;
  var halResourceTypesStorage:any;

  class HalResource {
  }
  class OtherResource {
  }

  beforeEach(angular.mock.module(opApiModule.name, $provide => {
    $provide.value('HalResource', HalResource);
    $provide.value('OtherResource', OtherResource);
  }));

  beforeEach(angular.mock.inject((_halResourceTypes_, _halResourceTypesStorage_) => {
    [halResourceTypes, halResourceTypesStorage] = arguments;
  }));

  it('should exist', () => {
    expect(halResourceTypes).to.exist;
  });


  describe('when adding configuration using add()', () => {
    var chained;
    var commonTests = () => {
      it('should return itself', () => {
        expect(chained).to.equal(halResourceTypes);
      });

      it('should add the attribute type config', () => {
        const resource = halResourceTypesStorage
          .getResourceClassOfAttribute('Other', 'someResource');

        expect(resource).to.equal(OtherResource);
      });
    };

    describe('when no class name is provided and attributes are configured', () => {
      beforeEach(() => {
        chained = halResourceTypes.add('Other', {
          attr: {
            someResource: 'OtherResource'
          }
        });
      });

      it('should add the respective class object', () => {
        expect(halResourceTypesStorage.getResourceClassOfType('Other')).to.equal(HalResource);
      });

      commonTests();
    });

    describe('when a class name is provided and attribute types are configured', () => {
      beforeEach(() => {
        chained = halResourceTypes.add('Other', {
          className: 'OtherResource',
          attr: {
            someResource: 'OtherResource'
          }
        });
      });

      it('should have the default type', () => {
        expect(halResourceTypesStorage.getResourceClassOfType('Other')).to.equal(OtherResource);
      });

      commonTests();
    });
  });
});
