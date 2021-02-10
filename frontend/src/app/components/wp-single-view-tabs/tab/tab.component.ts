import { Component } from '@angular/core';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}
