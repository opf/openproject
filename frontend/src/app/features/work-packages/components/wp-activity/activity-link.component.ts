import { Component, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  selector: 'activity-link',
  template: `
    <a id ="{{ activityHtmlId }}-link"
       [textContent]="activityLabel"
       uiSref="work-packages.show"
       [uiParams]="{workPackageId: workPackage.id!, '#': activityHtmlId }">
    </a>
  `,
})
export class ActivityLinkComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  @Input() public activityNo:number;

  public activityHtmlId:string;

  public activityLabel:string;

  ngOnInit() {
    this.activityHtmlId = `activity-${this.activityNo}`;
    this.activityLabel = `#${this.activityNo}`;
  }
}

function activityLink() {
  return {
    restrict: 'E',
    template: `
    `,
    scope: {
    },
    link(scope:any) {
      scope.workPackageId = scope.workPackage.id!;
      scope.activityHtmlId = `activity-${scope.activityNo}`;
    },
  };
}
