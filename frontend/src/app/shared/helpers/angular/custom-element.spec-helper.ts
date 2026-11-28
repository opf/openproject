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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationRef, Injector, Type } from '@angular/core';
import { createCustomElement } from '@angular/elements';
import { TestBed } from '@angular/core/testing';

export interface TestCustomElement {
  element:HTMLElement;
  set(name:string, value:string):Promise<void>;
  remove(name:string):Promise<void>;
}

let counter = 0;

async function stabilize():Promise<void> {
  await TestBed.inject(ApplicationRef).whenStable();
}

export async function defineTestCustomElement(
  component:Type<unknown>,
  attributes:Record<string, string|null>,
):Promise<TestCustomElement> {
  counter += 1;
  const tagName = `test-${counter}`;
  customElements.define(tagName, createCustomElement(component, { injector: TestBed.inject(Injector) }));

  const element = document.createElement(tagName);
  Object.entries(attributes).forEach(([name, value]) => {
    if (value !== null) element.setAttribute(name, value);
  });
  document.body.appendChild(element);
  await stabilize();

  return {
    element,
    async set(name, value) {
      element.setAttribute(name, value);
      await stabilize();
    },
    async remove(name) {
      element.removeAttribute(name);
      await stabilize();
    },
  };
}
