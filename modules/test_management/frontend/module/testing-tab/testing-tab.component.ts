import { ChangeDetectionStrategy, Component, Input, OnInit, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TabComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: 'op-tm-testing-tab',
  templateUrl: './testing-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class TestingTabComponent implements OnInit, TabComponent {
  readonly PathHelper = inject(PathHelperService);

  @Input() public workPackage:WorkPackageResource;

  turboFrameSrc:string;

  ngOnInit():void {
    this.turboFrameSrc = `${this.PathHelper.workPackagePath(this.workPackage.id as string)}/test_management/tab`;
  }
}
