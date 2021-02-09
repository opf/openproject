import {Type, Component} from '@angular/core';

import {WorkPackageBaseResource, WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}
export class Tab {
  constructor(
    public component:Type<TabComponent>,
    public displayName:string,
    public identifier:string,
    public displayable:(work_package:WorkPackageBaseResource) => boolean
  ) {}
}
