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

describe('lazy service', () => {
  var lazy:any;

  beforeEach(angular.mock.module('openproject.services'));
  beforeEach(angular.mock.inject((_lazy_:any) => {
    lazy = _lazy_;
  }));

  it('should exist', () => {
    expect(lazy).to.exist;
  });

  it('should add a property with the given name to the object', () => {
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', () => '');
    expect(obj.prop).to.exist;
  });

  it('should add an enumerable property', () => {
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', () => '');
    expect(obj.propertyIsEnumerable('prop')).to.be.true;
  });

  it('should add a configurable property', () => {
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', () => '');
    expect(Object.getOwnPropertyDescriptor(obj, 'prop').configurable).to.be.true;
  });

  it('should set the value of the property provided by the setter', () => {
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', () => '', (val:any) => val);
    obj.prop = 'hello';
    expect(obj.prop).to.eq('hello');
  });

  it('should not be settable, if no setter is provided', () => {
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', () => '');
    try {
      obj.prop = 'hello';
    }
    catch (Error) {}
    expect(obj.prop).to.not.eq('hello');
  });

  it('should do nothing if the target is not an object', () => {
    let obj = null;
    lazy(obj, 'prop', () => '');
    expect(obj).to.not.be.ok;
  });

  it('should call the getter only once', () => {
    let callback = sinon.spy();
    let obj:any = {
      prop: void 0
    };
    lazy(obj, 'prop', callback);
    obj.prop;
    obj.prop;
    expect(callback.calledOnce).to.be.true;
  });
});
