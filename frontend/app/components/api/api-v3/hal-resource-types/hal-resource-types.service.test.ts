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
import {HalResourceFactoryService} from '../hal-resource-factory/hal-resource-factory.service';

describe('halResourceTypes service', () => {
  var halResourceTypes:HalResourceTypesService;
  var halResourceFactory:HalResourceFactoryService;
  var config:any;
  var compareCls:typeof HalResource;

  class HalResource {
  }
  class OtherResource {
  }
  class FooResource {
  }

  beforeEach(angular.mock.module(opApiModule.name, ($provide:any) => {
    $provide.value('HalResource', HalResource);
    $provide.value('OtherResource', OtherResource);
    $provide.value('FooResource', FooResource);
  }));

  beforeEach(angular.mock.inject(function (_halResourceTypes_:any, _halResourceFactory_:any) {
    [halResourceTypes, halResourceFactory] = _.toArray(arguments);
  }));

  const expectResourceClassAdded = () => {
    it('should add the respective class object to the storage', () => {
      const resource = halResourceFactory.createHalResource({_type: 'Other'});
      expect(resource).to.be.an.instanceOf(compareCls);
    });
  };

  const expectAttributeClassAdded = () => {
    it('should add the attribute type config to the storage', () => {
      const resource = halResourceFactory.createLinkedHalResource({}, 'Other', 'attr');
      expect(resource).to.be.an.instanceOf(compareCls);
    });
  };

  it('should exist', () => {
    expect(halResourceTypes).to.exist;
  });

  describe('when configuring the type with class and attributes', () => {
    beforeEach(() => {
      compareCls = OtherResource;
      config = {
        Other: {
          className: 'OtherResource',
          attrTypes: {
            attr: 'Other'
          }
        }
      };
      halResourceTypes.setResourceTypeConfig(config);
    });

    expectResourceClassAdded();
    expectAttributeClassAdded();
  });

  describe('when configuring the type with the class name as value', () => {
    beforeEach(() => {
      compareCls = OtherResource;
      config = {
        Other: 'OtherResource'
      };
      halResourceTypes.setResourceTypeConfig(config);
    });

    expectResourceClassAdded();
  });

  describe('when configuring the type with only the attribute types', () => {
    beforeEach(() => {
      compareCls = halResourceFactory.defaultClass;
      config = {
        Other: {
          attr: 'Other'
        }
      };
      halResourceTypes.setResourceTypeConfig(config);
    });

    expectResourceClassAdded();
    expectAttributeClassAdded();
  });

  describe('when an attribute has a type, that defined later in the config', () => {
    beforeEach(() => {
      compareCls = FooResource;
      config = {
        Other: {
          attr: 'Foo'
        },
        Foo: 'FooResource',
      };
      halResourceTypes.setResourceTypeConfig(config);
    });

    expectAttributeClassAdded();
  });
});
