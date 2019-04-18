import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {Board} from "core-app/modules/boards/board/board";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {
  CardHighlightingMode,
  HighlightingMode
} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  templateUrl: './highlighting-tab.component.html'
})
export class BoardHighlightingTabComponent implements TabComponent {

  // Highlighting mode
  public highlightingMode:CardHighlightingMode = 'inline';
  public entireCardMode:boolean = false;
  public lastEntireCardAttribute:CardHighlightingMode = 'type';

  // Current board resource
  public board:Board;

  public text = {
    highlighting_mode: {
      description: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.description'),
      none: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.none'),
      inline: this.I18n.t('js.card.highlighting.inline'),
      status: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status'),
      type: this.I18n.t('js.work_packages.properties.type'),
      priority: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority'),
      entire_card_by: this.I18n.t('js.card.highlighting.entire_card_by'),
    }
  };

  constructor(readonly injector:Injector,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService) {
  }

  public onSave() {
    this.updateMode(this.highlightingMode);
    this.board.highlightingMode = this.highlightingMode;
  }

  ngOnInit() {
    this.board = this.locals.board;
    this.highlightingMode = this.board.highlightingMode;
    this.updateMode(this.highlightingMode);
  }

  public updateMode(mode:CardHighlightingMode) {
    if (mode === 'entire-card') {
      this.highlightingMode = this.lastEntireCardAttribute;
    } else {
      this.highlightingMode = mode;
    }

    if (['priority', 'type'].indexOf(this.highlightingMode) !== -1) {
      this.lastEntireCardAttribute = this.highlightingMode;
      this.entireCardMode = true;
    } else {
      this.entireCardMode = false;
    }

  }
}
