import {
  ChangeDetectionStrategy,
  Component,
  ViewEncapsulation,
  HostBinding,
  Input,
} from '@angular/core';

@Component({
  selector: 'op-wp-loading-skeleton',
  templateUrl: './op-wp-loading-skeleton.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./op-wp-loading-skeleton.component.sass'],
})
export class OpWPLoadingComponent {
  @HostBinding('class.op-wp-loading-skeleton--loader') className = true;
  @Input() public viewBox?:string = '0 0 2000 80';
}
