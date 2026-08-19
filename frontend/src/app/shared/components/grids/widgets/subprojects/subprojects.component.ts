import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { AbstractTurboWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-turbo-widget.component';

@Component({
  selector: 'op-subitems-widget',
  templateUrl: './subprojects.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WidgetSubprojectsComponent extends AbstractTurboWidgetComponent {
  override frameId = 'grids-widgets-subitems';
  override name = 'subitems';
}
