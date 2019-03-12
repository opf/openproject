import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {Board} from "core-app/modules/boards/board/board";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";

@Component({
  templateUrl: './highlighting-tab.component.html'
})
export class BoardHighlightingTabComponent implements TabComponent {

  // Current board resource
  public board:Board;

  public text = {
    choose_mode: this.I18n.t('js.work_packages.table_configuration.choose_display_mode'),
  };

  constructor(readonly injector:Injector,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService) {
  }

  public onSave() {
  }

  ngOnInit() {
    this.board = this.locals.board;
  }
}
