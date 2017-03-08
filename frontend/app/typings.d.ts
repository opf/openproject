/// <reference path="../tests/typings/tests.d.ts" />


/*
 monkey patch noUiSlider
 */
declare namespace noUiSlider {
  //noinspection JSUnusedGlobalSymbols
  interface Options {
    tooltips: boolean;
  }
}
