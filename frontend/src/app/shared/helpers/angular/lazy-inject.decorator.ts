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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import 'reflect-metadata';
import { InjectOptions, Injector, ProviderToken } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';

export interface InjectableClass {
  injector:Injector;
}

export function LazyInject<T = unknown>(
  token?:ProviderToken<T>,
  defaultValue:T | null = null,
  options?:InjectOptions,
) {
  return (target:InjectableClass, property:string):void => {
    if (delete (target as unknown as Record<string, unknown>)[property]) {
      Object.defineProperty(target, property, {
        get(this:InjectableClass):T | null {
          // When no token is given, fall back to the property's reflected
          // design type (requires emitDecoratorMetadata).
          const resolvedToken = (token
            ?? Reflect.getMetadata('design:type', target, property)) as ProviderToken<T>;
          return this.injector.get(resolvedToken, defaultValue, options);
        },
        set(this:InjectableClass):void {
          debugLog(`Trying to set LazyInject property ${property}`);
        },
      });
    }
  };
}
