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
  public highlightingMode:HighlightingMode = 'inline';

  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.highlighting'),
    highlighting_mode: {
      description: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.description'),
      none: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.none'),
      none_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.none_text'),
      inline: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.inline'),
      inline_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.inline_text'),
      status: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status'),
      status_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status_text'),
      priority: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority'),
      priority_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority_text')
    }
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableHighlight:WorkPackageTableHighlightingService) {
  }

  public onSave() {
    this.wpTableHighlight.update(this.highlightingMode);
  }

  public get selectedModeDescription() {
    return (this.text.highlighting_mode as any)[`${this.highlightingMode}_text`];
  }

  ngOnInit() {
    this.highlightingMode = this.wpTableHighlight.current;
  }
}
