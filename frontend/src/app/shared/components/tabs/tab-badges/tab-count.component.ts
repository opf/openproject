import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { Observable } from 'rxjs';

@Component({
  selector: 'op-tab-count',
  templateUrl: './tab-count.component.html',
  styleUrls: ['./tab-count.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TabCountComponent {
  @Input('counter') counter$:Observable<number>;
}
