import 'reflect-metadata';
import { ElementRef } from '@angular/core';

export interface InjectableClass {
  elementRef:ElementRef;
  [key:string]:any;
}

export function DatasetInputs<T extends { new(...args:any[]):InjectableClass }>(constructor:T):any {
  return class extends constructor {
    constructor(...args:any[]) {
      super(...args);

      // TypeScript won't allow us to do the necessary metaprogramming here since it does not
      // know about these keys (probably because we should not touch them)
      const cstr = constructor as any;

      // Here we find the declared input names of the component.
      // With them way we can make sure we don't overwrite any non-input values.
      // This seems to always be ɵcmp, but we don't want to depend on that knowledge.
      // FIXME: Is there a better way to get to this information? It does not seem to be part of Reflect metadata
      const declaredInputsParentKey = Object.keys(cstr)
        .find((key:string) => typeof cstr[key].declaredInputs === 'object');

      if (!declaredInputsParentKey) {
        throw new Error('Could not find declared inputs for component');
      }
      
      const inputs = cstr[declaredInputsParentKey].declaredInputs as { [key:string]:string };

      Object.keys(inputs)
        .forEach((outsideName) => {
          const insideName = inputs[outsideName];

          const dataset = this.elementRef.nativeElement.dataset;

          if (!dataset[outsideName]) {
            return;
          }

          try {
            this[insideName] = JSON.parse(dataset[outsideName]);
          } catch (err) {
            console.error(err);
            console.error("Couldn't parse input: ", outsideName, this.elementRef.nativeElement.dataset);
            console.error("Make sure to make all data attributes you want to use as input JSON parseable. This means\
                          that plain strings have to be wrapped in double quotes, and the attribute value is easiest to\
                          set with single quotes. An example:\n\n<op-example example-input='\"myString\"'></op-example>");
          }
        });
    }
  };
}
