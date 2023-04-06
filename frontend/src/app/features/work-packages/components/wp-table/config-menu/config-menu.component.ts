import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Component, Injector } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WpTableConfigurationModalComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';

@Component({
  templateUrl: './config-menu.template.html',
  selector: 'wp-table-config-menu',
})
export class WorkPackagesTableConfigMenuComponent {
  public text = {
    configureTable: this.I18n.t('js.toolbar.settings.configure_view'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly opModalService:OpModalService,
    readonly opContextMenu:OPContextMenuService,
  ) { }

  public openTableConfigurationModal() {
    this.opContextMenu.close();
    this.opModalService.show(WpTableConfigurationModalComponent, this.injector);
  }
}
