import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
  selector: 'op-tab-count',
  templateUrl: './tab-count.component.html',
  styleUrls: ['./tab-count.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TabCountComponent {
  @Input() count:number;
}
