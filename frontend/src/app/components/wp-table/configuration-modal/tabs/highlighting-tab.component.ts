import {Component, Injector} from '@angular/core';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {
  WorkPackageTableHighlightingService
} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";

@Component({
  templateUrl: './highlighting-tab.component.html'
})
export class WpTableConfigurationHighlightingTab implements TabComponent {

  // Display mode
  public highlightingMode:HighlightingMode|'entire-row'|'in-cell' = 'inline';
  public entireRowMode:boolean = false;
  public inCellMode:boolean = false;
  public lastEntireRowAttribute:HighlightingMode = 'status';
  public lastInCellAttribute:HighlightingMode = 'inline';

  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.highlighting'),
    highlighting_mode: {
      as_inline_or_cell: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.as_inline_or_cell'),
      description: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.description'),
      cell: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.cell'),
      inline: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.inline'),
      none: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.none'),
      status: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status'),
      priority: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority'),
      entire_row_by: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.entire_row_by'),
    }
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableHighlight:WorkPackageTableHighlightingService) {
  }

  public onSave() {
    this.wpTableHighlight.update(this.highlightingMode as HighlightingMode);
  }

  public updateMode(mode:HighlightingMode|'entire-row'|'in-cell') {
    if (mode === 'entire-row') {
      this.highlightingMode = this.lastEntireRowAttribute;
    } else if (mode === 'in-cell') {
      this.highlightingMode = this.lastInCellAttribute;
    } else {
      this.highlightingMode = mode;
    }

    if (this.highlightingMode === 'status' || this.highlightingMode === 'priority') {
      this.lastEntireRowAttribute = this.highlightingMode;
      this.entireRowMode = true;
      this.inCellMode = false;
    } else if (this.highlightingMode === 'inline' || this.highlightingMode === 'cell') {
      this.lastInCellAttribute = this.highlightingMode;
      this.entireRowMode = false;
      this.inCellMode = true;
    } else {
      this.entireRowMode = false;
      this.inCellMode = false;
    }
  }

  ngOnInit() {
    this.updateMode(this.wpTableHighlight.current);
  }
}
