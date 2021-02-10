import { Type } from '@angular/core';
import { WorkPackageBaseResource } from 'core-app/modules/hal/resources/work-package-resource';
import { TabComponent } from './tab.component';

export class Tab {
  constructor(
    public component:Type<TabComponent>,
    public displayName:string,
    public identifier:string,
    public displayable:(work_package:WorkPackageBaseResource) => boolean
  ) {}
}
