import {Component, Input, OnInit} from "@angular/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Component({
  selector: 'activity-link',
  template: `
    <a id ="{{ activityHtmlId }}-link"
       [textContent]="activityLabel"
       uiSref="work-packages.show.activity"
       [uiParams]="{workPackageId: workPackage.id!, '#': activityHtmlId }">
    </a>
  `
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
    link: function(scope:any) {
      scope.workPackageId = scope.workPackage.id!;
      scope.activityHtmlId = 'activity-' + scope.activityNo;
    }
  };
}
