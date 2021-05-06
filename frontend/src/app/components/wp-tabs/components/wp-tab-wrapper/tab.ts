import { Component, Injector, Type } from '@angular/core';

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { StateDeclaration } from "@uirouter/core";
import { StateParams } from "@uirouter/core/lib/params/stateParams";
import { Observable } from "rxjs";
import { StateService } from "@uirouter/angular";

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}

export interface Tab {
  component:Type<TabComponent>;
  name:string;
  identifier:string;
}

export interface TabDefinition extends Tab {
  displayable?:(workPackage:WorkPackageResource, $state:StateService) => boolean;
  count?:(workPackage:WorkPackageResource, injector:Injector) => Observable<number>;
}

export interface TabInstance extends Tab {
  counter?:Observable<number>;
}

