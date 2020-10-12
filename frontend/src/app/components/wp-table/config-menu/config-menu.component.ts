import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Component, OnInit, Injector} from '@angular/core';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {WpTableConfigurationModalComponent} from "core-components/wp-table/configuration-modal/wp-table-configuration.modal";

@Component({
  templateUrl: './config-menu.template.html',
  selector: 'wp-table-config-menu',
})
export class WorkPackagesTableConfigMenu implements OnInit {
  public text:any;

  constructor(readonly I18n:I18nService,
              readonly injector:Injector,
              readonly opModalService:OpModalService,
              readonly opContextMenu:OPContextMenuService) {
  }

  ngOnInit():void {
    this.text = {
      configureTable: I18n.t('js.toolbar.settings.configure_view')
    };
  }

  public openTableConfigurationModal() {
    this.opContextMenu.close();
    this.opModalService.show(WpTableConfigurationModalComponent, this.injector);
  }
}
