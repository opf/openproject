import { Component, Input } from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'enterprise-banner',
  styleUrls: ['./enterprise-banner.component.sass'],
  template: `
    <div class="op-enterprise-banner">
      <div class="op-toast -ee-upsale"
           [ngClass]="{'-left-margin': leftMargin }">
        <div class="op-toast--content">
          <p class="-bold" [textContent]="text.enterpriseFeature"></p>
          <p [textContent]="textMessage"></p>
          <a [href]="eeLink()"
             target='blank'
             [textContent]="linkMessage"></a>
        </div>
      </div>
    </div>
  `
})
export class EnterpriseBannerComponent {
  @Input() public leftMargin = false;

  @Input() public textMessage:string;

  @Input() public linkMessage:string;

  @Input() public opReferrer:string;

  public text:any = {
    enterpriseFeature: this.I18n.t('js.upsale.ee_only'),
  };

  constructor(
    protected I18n:I18nService,
    protected bannersService:BannersService,
  ) {}

  public eeLink() {
    this.bannersService.getEnterPriseEditionUrl({ referrer: this.opReferrer });
  }
}
