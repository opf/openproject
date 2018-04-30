import {downgradeComponent} from '@angular/upgrade/static';
import * as angular from 'angular';
import {AppComponent} from './app.component';


export class Ng1DirectiveController {
  label = 'AngularJS';
}


function ng1Directive():any {
  return {
    restrict: 'E',
    template: `
        ng1directive
        <span>{{$ctrl.label}}</span>
        <app-component></app-component>
    `,
    controller: Ng1DirectiveController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

const ng1Module = angular.module('ng1mod', []);

ng1Module.directive('appComponent',
  downgradeComponent({component: AppComponent})
);

ng1Module.directive('ng1directive', ng1Directive);
