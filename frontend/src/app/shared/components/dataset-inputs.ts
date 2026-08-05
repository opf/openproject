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
import {
  Component,
  ElementRef,
  ɵDirectiveDef,
} from '@angular/core';

/** We expect an ElementRef to be present on the target class */
export interface DatasetInputsDecorated extends Component {
  elementRef:ElementRef<HTMLElement>;
}

export interface DatasetInputsComponent extends DatasetInputsDecorated {
  elementRef:ElementRef<HTMLElement>;
  [key:string]:unknown;
}

/**
 * The populateInputsFromDataset function automatically sets input values from `data` attributes set on a component tag.
 * This is useful if you're rendering the tag in the backend but want to provide data to the component via its inputs.
 *
 * Usage:
 *
 * ```
 * @Component({ selector: 'my-component' })
 * export class MyComponent {
 *   @Input() someInput:string[] = [];
 *
 *   constructor(
 *    elementRef:ElementRef,
 *   ) {
 *     populateInputsFromDataset(this);
 *   }
 * }
 * ```
 *
 * Now you can send data from the backend to the component by JSON:
 *
 * <%= content_tag 'my-component',
 *                 '',
 *                 data: {
 *                   'some-input': ['a', 'b'].to_json
 *                 }
 * %>
 * Warning: this is only checked during the constructor phase once. Changes to the dataset
 * will not be reflected in the inputs. If you need inputs that update, use normal Angular bindings.
 */
/* eslint-disable-next-line @typescript-eslint/no-explicit-any */
export function populateInputsFromDataset(instance:DatasetInputsDecorated):any {
  // TypeScript won't allow us to do the necessary metaprogramming here since it does not
  // know about these keys (probably because we should not touch them)
  const cstr = instance.constructor as unknown as DatasetInputsComponent;

  // Here we find the declared input names of the component.
  // With them way we can make sure we don't overwrite any non-input values.
  // This seems to always be ɵcmp, but we don't want to depend on that knowledge.
  // FIXME: Is there a better way to get to this information? It does not seem to be part of Reflect metadata
  const declaredInputsParentKey = Object.keys(cstr)
    .find((key:string) => typeof (cstr[key] as ɵDirectiveDef<unknown>).declaredInputs === 'object');

  if (!declaredInputsParentKey) {
    console.warn('Could not find declared inputs for component');
    return;
  }

  const input = cstr[declaredInputsParentKey] as ɵDirectiveDef<unknown>;
  const inputs = input.declaredInputs;

  Object.keys(inputs)
    .forEach((outsideName) => {
      const insideName = inputs[outsideName];

      const { dataset } = (instance as unknown as DatasetInputsComponent).elementRef.nativeElement;

      if (!dataset[outsideName]) {
        return;
      }

      try {
        (instance as unknown as DatasetInputsComponent)[insideName] = JSON.parse(dataset[outsideName] || '');
      } catch (err) {
        console.error("Couldn't parse input: ", outsideName, instance.elementRef.nativeElement.dataset);
        console.error(`
Make sure to make all data attributes you want to use as input JSON parseable.
This means that plain strings have to be wrapped in double quotes, and the attribute value is easiest to set with single quotes.
An example:

<op-example example-input='"myString"'></op-example>
`);

        // Rethrow since an error at this point is basically a syntax error and should be fixed
        throw err;
      }
    });
}
