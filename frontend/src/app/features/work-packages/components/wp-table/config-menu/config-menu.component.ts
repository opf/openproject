import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ChangeDetectionStrategy, Component, Injector, inject } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WpTableConfigurationModalComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';

@Component({
  templateUrl: './config-menu.template.html',
  selector: 'wp-table-config-menu',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WorkPackagesTableConfigMenuComponent {
  readonly I18n = inject(I18nService);
  readonly injector = inject(Injector);
  readonly opModalService = inject(OpModalService);
  readonly opContextMenu = inject(OPContextMenuService);

  public text = {
    configureTable: this.I18n.t('js.toolbar.settings.configure_view'),
  };

  public openTableConfigurationModal() {
    this.opContextMenu.close();
    this.opModalService.show(WpTableConfigurationModalComponent, this.injector);
  }
}
