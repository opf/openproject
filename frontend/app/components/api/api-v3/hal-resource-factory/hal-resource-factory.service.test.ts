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
import {HalResourceFactoryService} from './hal-resource-factory.service';
import {HalResource} from '../hal-resources/hal-resource.service';

describe('halResourceFactory', () => {
  var halResourceFactory:HalResourceFactoryService;
  var resource:HalResource;

  class OtherResource extends HalResource {
  }

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.module(opApiModule.name, ($provide:any) => {
    $provide.value('OtherResource', OtherResource);
  }));
  beforeEach(angular.mock.inject(function (_halResourceFactory_:any) {
    [halResourceFactory] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(halResourceFactory).to.exist;
  });

  it('should have HalResource as its default class', () => {
    expect(halResourceFactory.defaultClass).to.equal(HalResource);
  });

  describe('when no resource type is configured', () => {
    describe('when creating a resource', () => {
      beforeEach(() => {
        resource = halResourceFactory.createHalResource({});
      });

      it('should create an instance of the default type', () => {
        expect(resource).to.be.an.instanceOf(halResourceFactory.defaultClass);
      });
    });
  });

  describe('when a resource type is configured', () => {
    beforeEach(() => {
      halResourceFactory.setResourceType('Other', OtherResource);
    });

    describe('when creating a resource of that type', () => {
      beforeEach(() => {
        resource = halResourceFactory.createHalResource({_type: 'Other'});
      });

      it('should be an instance of the configured type', () => {
        expect(resource).to.be.an.instanceOf(OtherResource);
      });
    });

    describe('when adding attribute configuration for that type', () => {
      beforeEach(() => {
        halResourceFactory.setResourceTypeAttributes('Other', {
          attr: 'Other'
        });
        resource = halResourceFactory.createLinkedHalResource({}, 'Other', 'attr');
      });

      it('should be an instance of the configured attr type', () => {
        expect(resource).to.be.an.instanceOf(OtherResource);
      });
    });
  });

  describe('when adding attr type configuration to for a non configured type', () => {
    beforeEach(() => {
      halResourceFactory.setResourceTypeAttributes('NonExistent', {
        attr: 'NonExistent'
      });
      resource = halResourceFactory.createLinkedHalResource({}, 'NonExistent', 'attr');
    });

    it('should create a resource from the default tpye', () => {
      expect(resource).to.be.an.instanceOf(halResourceFactory.defaultClass);
    });
  });
});
