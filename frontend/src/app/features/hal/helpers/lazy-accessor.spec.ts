//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { OpenprojectHalModuleHelpers } from 'core-app/features/hal/helpers/lazy-accessor';

describe('lazy service', () => {
  const { lazy } = OpenprojectHalModuleHelpers;

  it('should exist', () => {
    expect(lazy).toBeDefined();
  });

  it('should add a property with the given name to the object', () => {
    const obj:any = {
      prop: void 0,
    };
    lazy(obj, 'prop', () => '');
    expect(obj.prop).toBeDefined();
  });

  it('should add an enumerable property', () => {
    const obj:any = {
      prop: void 0,
    };
    lazy(obj, 'prop', () => '');
    expect(obj.propertyIsEnumerable('prop')).toBeTruthy();
  });

  it('should add a configurable property', () => {
    const obj:any = {
      prop: void 0,
    };
    lazy(obj, 'prop', () => '');
    expect((Object as any).getOwnPropertyDescriptor(obj, 'prop').configurable).toBeTruthy();
  });

  it('should set the value of the property provided by the setter', () => {
    const obj:any = {
      prop: void 0,
    };
    lazy(obj, 'prop', () => '', (val:any) => val);
    obj.prop = 'hello';
    expect(obj.prop).toEqual('hello');
  });

  it('should not be settable, if no setter is provided', () => {
    const obj:any = {
      prop: void 0,
    };
    lazy(obj, 'prop', () => '');
    try {
      obj.prop = 'hello';
    } catch (Error) {}
    expect(obj.prop).not.toEqual('hello');
  });

  it('should do nothing if the target is not an object', () => {
    const obj:any = null;
    lazy(obj, 'prop', () => '');
    expect(obj).toBeNull();
  });
});
