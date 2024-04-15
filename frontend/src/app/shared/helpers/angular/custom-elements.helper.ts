import 'reflect-metadata';
import { Type } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { createCustomElement, NgElementConfig } from '@angular/elements';

export function registerCustomElement(name:string, component:Type<unknown>, config:NgElementConfig) {
  const wrappedElement = createCustomElement(component, config);
  if (customElements.get(name)) {
    debugLog(`${name} custom element already registered.`);
    return;
  }

  customElements.define(name, wrappedElement);
}
