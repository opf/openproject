import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
} from '@angular/core';
import { AbstractTurboWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-turbo-widget.component';

@Component({
  selector: 'op-favorite-projects-widget',
  templateUrl: './widget-favorite-projects.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WidgetFavoriteProjectsComponent extends AbstractTurboWidgetComponent {
  @HostBinding('class.op-widget-favorite-projects') className = true;

  override frameId = 'grids-widgets-favorite-projects';
  override name = 'project_favorites';
}
