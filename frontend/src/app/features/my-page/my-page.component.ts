import { ChangeDetectionStrategy, Component, ViewEncapsulation } from '@angular/core';
import { GRID_PROVIDERS } from 'core-app/shared/components/grids/grid/grid.component';
import { GridPageComponent } from 'core-app/shared/components/grids/grid/page/grid-page.component';

@Component({
  templateUrl: '../../shared/components/grids/grid/page/grid-page.component.html',
  styleUrls: ['../../shared/components/grids/grid/page/grid-page.component.sass'],
  providers: GRID_PROVIDERS,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class MyPageComponent extends GridPageComponent {
  protected gridScopePath():string {
    return this.pathHelper.myPagePath();
  }
}
