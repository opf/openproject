import {Component, ElementRef, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export const enterpriseBannerSelector = 'enterprise-banner-bootstrap';

@Component({
  selector: enterpriseBannerSelector,
  template: `
    <enterprise-banner
      [textMessage]="textMessage"
      [linkMessage]="linkMessage"
      [opReferrer]="referrer">
    </enterprise-banner>
  `
})
export class EnterpriseBannerBootstrapComponent implements OnInit {
  public textMessage:string;
  public linkMessage:string;
  public referrer:string;

  constructor(protected elementRef:ElementRef,
              protected i18n:I18nService) {
  }

  ngOnInit() {
    let $element = jQuery(this.elementRef.nativeElement);

    this.textMessage = $element.attr('text-message')!;
    this.linkMessage = $element.attr('link-message') || this.i18n.t('js.work_packages.table_configuration.upsale.check_out_link');
    this.referrer = $element.attr('referrer')!;
  }
}
