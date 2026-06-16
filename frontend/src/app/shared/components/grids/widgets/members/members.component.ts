import {
  ChangeDetectionStrategy,
  Component,
  inject,
} from '@angular/core';
import { AbstractTurboWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-turbo-widget.component';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

@Component({
  selector: 'op-members-widget',
  templateUrl: './members.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WidgetMembersComponent extends AbstractTurboWidgetComponent {
  protected readonly currentUser = inject(CurrentUserService);

  text = {
    missing_permission: this.i18n.t('js.grid.widgets.missing_permission'),
  };

  hasCapability$ = this.currentUser.hasCapabilities$('memberships/read', this.currentProject.id);

  public get projectIdentifier() {
    return this.currentProject.identifier;
  }

  override frameId = 'grids-widgets-members';
  override name = 'members';
}
