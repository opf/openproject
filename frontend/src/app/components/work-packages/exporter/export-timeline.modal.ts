import {ChangeDetectorRef, Component, ElementRef, Inject, OnInit, SecurityContext, ViewChild} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {
  LoadingIndicatorService,
  withDelayedLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {JobStatusEnum, JobStatusInterface} from "core-app/modules/job-status/job-status.interface";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import { TimelineZoomLevel } from 'core-app/modules/hal/resources/query-resource';
import { ExportTimelineConfig } from './ExportTimelineConfig';
import jsPDF from 'jspdf';
import { DomSanitizer, SafeResourceUrl, SafeUrl} from '@angular/platform-browser';
import { HookService } from 'core-app/modules/plugins/hook-service';
import { FormControl } from '@angular/forms';


@Component({
  templateUrl: './export-timeline.modal.html',
  styleUrls: ['./export-timeline.modal.sass']
})
export class ExportTimelineModal extends OpModalComponent implements OnInit {

  @ViewChild('pdfPreview') pdfPreview: HTMLIFrameElement;

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click */
  public closeOnOutsideClick = false;

  public text = {
    title: this.I18n.t('js.timelines.gantt_chart'),
    closePopup: this.I18n.t('js.close_popup_title'),
    btn_export: this.I18n.t('js.button_export-pdf'),
  };

  /** Title to show */
  public title:string = this.text.title;

  public filename = '';
  public doc:jsPDF;

  public zooms:{
    level: TimelineZoomLevel,
    label: string
   }[] = [
    {level: 'years', label: this.I18n.t('js.timelines.zoom.years')},
    {level: 'quarters', label: this.I18n.t('js.timelines.zoom.quarters')},
    {level: 'months', label: this.I18n.t('js.timelines.zoom.months')},
    {level: 'weeks', label: this.I18n.t('js.timelines.zoom.weeks')},
    {level: 'days', label: this.I18n.t('js.timelines.zoom.days')},
  ];

  public config: ExportTimelineConfig = {
    lineHeight: 20,
    workHeight: 10,
    fitDateInterval: true,
    fitDateIntervalMarginFactor: 0.1,
    startDate: moment({hour: 0, minute: 0, seconds: 0}),
    endDate: moment({hour: 0, minute: 0, seconds: 0}).add(1, 'day'),
    zoomLevel: 'days',
    pixelPerDay: 1,
    fontSize: 12,
    nameColumnSize: 200,
    boldLineColor: '#333333',
    normalLineColor: '#333333',
    smallLineColor: '#dddddd',
    todayLineColor: '#e74c3c',
    relationLineColor: '#3498db',
    groupBackgroundColor: '#f8f8f8',

    headerLine1Height: 20,
    headerLine1FontStyle: 'bold',
    headerLine1FontSize: 10,
    headerLine2Height: 10,
    headerLine2FontStyle: 'normal',
    headerLine2FontSize: 10,
    headerLine3Height: 25,
    headerLine3FontStyle: 'normal',
    headerLine3FontSize: 10,
  }

  public pdfPreviewUrl: SafeResourceUrl;

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              readonly elementRef:ElementRef,
              readonly pathHelper:PathHelperService,
              readonly apiV3Service:APIV3Service,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly notifications:NotificationsService,
              private sanitizer: DomSanitizer,
              private hook: HookService) {
    super(locals, cdRef, elementRef);
    this.filename = 'timeline.pdf';
    this.updatePreview();
  }

  ngOnInit() {
    super.ngOnInit();
  }

  public updatePreview() {
    console.info('updatePreview', this.config);
    this.hook.call('export-gantt', this.config, (doc: jsPDF) => {
      this.pdfPreviewUrl = this.sanitizer.bypassSecurityTrustResourceUrl(doc.output('datauristring'));
      console.log('Updated pdf', doc);
      console.log(this.pdfPreviewUrl);
      this.doc = doc;
    })
  }

  public savePdf() {
    this.hook.call('export-gantt', this.config, (doc: jsPDF) => {
      doc.save(this.filename);
    })
  }

  public openPdf() {
    if (this.doc) {
      this.doc.output('dataurlnewwindow');
    }
  }
}
