import {Component, Inject, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {TimelineLabels} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {QueryColumn} from 'core-components/wp-query/query-column';

@Component({
  template: require('!!raw-loader!./timelines-tab.component.html')
})
export class WpTableConfigurationTimelinesTab implements TabComponent {

  public timelineVisible:boolean = false;
  public availableAttributes:{ id:string, name:string }[];

  public labels:TimelineLabels;
  public availableLabels:string[];

  public text = {
    title: this.I18n.t('js.timelines.gantt_chart'),
    display_timelines: this.I18n.t('js.timelines.button_activate'),
    display_timelines_hint: this.I18n.t('js.work_packages.table_configuration.show_timeline_hint'),
    labels: {
      title: this.I18n.t('js.timelines.labels.title'),
      description: this.I18n.t('js.timelines.labels.description'),
      bar: this.I18n.t('js.timelines.labels.bar'),
      none: this.I18n.t('js.timelines.filter.noneSelection'),
      left: this.I18n.t('js.timelines.labels.left'),
      right: this.I18n.t('js.timelines.labels.right'),
      farRight: this.I18n.t('js.timelines.labels.farRight')
    }
  };

  constructor(readonly injector:Injector,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly wpTableTimeline:WorkPackageTableTimelineService,
              readonly wpTableColumns:WorkPackageTableColumnsService) {
  }

  public onSave() {
    this.wpTableTimeline.setVisible(this.timelineVisible);
    this.wpTableTimeline.updateLabels(this.labels);
  }

  public updateLabels(key:keyof TimelineLabels, value:string|null) {
    if (value === '') {
      value = null;
    }

    this.labels[key] = value;
  }

  ngOnInit() {
    this.timelineVisible = this.wpTableTimeline.isVisible;

    // Current label models
    const labels = this.wpTableTimeline.labels;
    this.labels = _.clone(labels);
    this.availableLabels = Object.keys(this.labels);

    // Available labels
    const availableColumns = this.wpTableColumns
      .allPropertyColumns
      .sort((a:QueryColumn, b:QueryColumn) => a.name.localeCompare(b.name));

    this.availableAttributes = [{ id: '', name: this.text.labels.none }].concat(availableColumns);
  }
}
