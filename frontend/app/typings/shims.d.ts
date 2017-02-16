// Declare some globals
// to work around previously magical global constants
// provided by typings@global

// Active issue
// https://github.com/Microsoft/TypeScript/issues/10178

import * as LodashObj from 'lodash';

declare global {
  const _:typeof LodashObj;
}

export {};