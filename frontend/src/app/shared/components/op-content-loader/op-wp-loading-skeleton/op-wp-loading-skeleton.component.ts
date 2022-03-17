import {
  ChangeDetectionStrategy,
  Component,
  ViewEncapsulation,
  HostBinding,
} from '@angular/core';

@Component({
  selector: 'op-wp-loading-skeleton',
  templateUrl: './op-wp-loading-skeleton.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class OpWPLoadingComponent {
  @HostBinding('class.op-wp-loading-skeleton--loader') className = true;
}
