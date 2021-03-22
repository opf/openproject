import { Component, Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { TabComponent } from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import { WorkPackageViewTimelineService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { TimelineLabels, TimelineZoomLevel } from 'core-app/modules/hal/resources/query-resource';
import { WorkPackageViewColumnsService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { QueryColumn } from 'core-components/wp-query/query-column';
import { zoomLevelOrder } from "core-components/wp-table/timeline/wp-timeline";

@Component({
  templateUrl: './timelines-tab.component.html'
})
export class WpTableConfigurationTimelinesTab implements TabComponent {

  public timelineVisible = false;
  public availableAttributes:{ id:string, name:string }[];

  public labels:TimelineLabels;
  public availableLabels:string[];

  public zoomLevel:TimelineZoomLevel;

  // Manualy build available zoom levels with zoom
  // because it is not part of the order.
  public availableZoomLevels:TimelineZoomLevel[] = ['auto', ...zoomLevelOrder];

  public text = {
    title: this.I18n.t('js.timelines.gantt_chart'),
    display_timelines: this.I18n.t('js.timelines.button_activate'),
    display_timelines_hint: this.I18n.t('js.work_packages.table_configuration.show_timeline_hint'),
    zoom: {
      level: this.I18n.t('js.tl_toolbar.zooms'),
      description: this.I18n.t('js.timelines.zoom.description'),
      days: this.I18n.t('js.timelines.zoom.days'),
      weeks: this.I18n.t('js.timelines.zoom.weeks'),
      months: this.I18n.t('js.timelines.zoom.months'),
      quarters: this.I18n.t('js.timelines.zoom.quarters'),
      years: this.I18n.t('js.timelines.zoom.years'),
      auto: this.I18n.t('js.timelines.zoom.auto')
    },
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
              readonly I18n:I18nService,
              readonly wpTableTimeline:WorkPackageViewTimelineService,
              readonly wpTableColumns:WorkPackageViewColumnsService) {
  }

  public onSave() {
    this.wpTableTimeline.update({
      ...this.wpTableTimeline.current,
      visible: this.timelineVisible,
      labels: this.labels,
      zoomLevel: this.zoomLevel
    });
  }

  public updateLabels(key:keyof TimelineLabels, value:string|null) {
    if (value === '') {
      value = null;
    }

    this.labels[key] = value;
  }

  ngOnInit() {
    this.timelineVisible = this.wpTableTimeline.isVisible;

    // Current zoom level
    this.zoomLevel = this.wpTableTimeline.zoomLevel;

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
