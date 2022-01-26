import { Component, Injector, Type } from '@angular/core';
import { Observable } from 'rxjs';
import { StateService } from '@uirouter/angular';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}

export interface WpTabDefinition extends TabDefinition {
  component:Type<TabComponent>;
  displayable?:(workPackage:WorkPackageResource, $state:StateService) => boolean;
  count?:(workPackage:WorkPackageResource, injector:Injector) => Observable<number>;
  showCountAsBubble?:boolean;
}
