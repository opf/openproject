import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'enterprise-banner',
  styleUrls: ['./enterprise-banner.component.sass'],
  templateUrl: './enterprise-banner.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EnterpriseBannerComponent implements OnInit {
  @Input() public leftMargin = false;

  @Input() public textMessage:string;

  @Input() public linkMessage:string;

  @Input() public opReferrer:string;

  public link:string;

  public text:any = {
    enterpriseFeature: this.I18n.t('js.upsale.ee_only'),
  };

  constructor(
    protected I18n:I18nService,
    protected bannersService:BannersService,
  ) {}

  ngOnInit():void {
    this.link = this.bannersService.getEnterPriseEditionUrl({ referrer: this.opReferrer });
  }
}
