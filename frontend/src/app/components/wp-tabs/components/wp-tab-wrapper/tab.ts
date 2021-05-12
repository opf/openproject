import { Component, Injector, Type } from '@angular/core';

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { StateDeclaration } from "@uirouter/core";
import { StateParams } from "@uirouter/core/lib/params/stateParams";
import { Observable } from "rxjs";
import { StateService } from "@uirouter/angular";
import { TabDefinition } from "core-app/modules/common/tabs/tab.interface";

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}

export interface WpTabDefinition extends TabDefinition {
  component:Type<TabComponent>;
  displayable?:(workPackage:WorkPackageResource, $state:StateService) => boolean;
  count?:(workPackage:WorkPackageResource, injector:Injector) => Observable<number>;
}

