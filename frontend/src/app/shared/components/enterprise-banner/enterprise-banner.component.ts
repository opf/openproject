import { ChangeDetectionStrategy, Component, ElementRef, Injector, Input, OnInit } from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { OpModalService } from '../modal/modal.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { pricingUrl } from 'core-app/core/setup/globals/constants.const';

@Component({
  selector: 'op-enterprise-banner',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./enterprise-banner.component.sass'],
  templateUrl: './enterprise-banner.component.html',
})
export class EnterpriseBannerComponent implements OnInit {
  @Input() public leftMargin = false;

  @Input() public textMessage:string;

  @Input() public linkMessage:string;

  @Input() public opReferrer:string;

  @Input() public moreInfoLink:string;

  @Input() public collapsible:boolean;

  public collapsed = false;

  link:string;

  pricingUrl = pricingUrl;

  text = {
    enterpriseFeature: this.I18n.t('js.upsale.ee_only'),
    become_hero: this.I18n.t('js.admin.enterprise.upsale.become_hero'),
    you_contribute: this.I18n.t('js.admin.enterprise.upsale.you_contribute'),
    button_trial: this.I18n.t('js.admin.enterprise.upsale.button_start_trial'),
    upgrade: this.I18n.t('js.admin.enterprise.upsale.button_upgrade'),
    more_info_link: `${this.pathHelper.appBasePath}/admin/enterprise`,
    more_info_text: this.I18n.t('js.admin.enterprise.upsale.more_info'),
  };

  image = {
    enterprise_edition: imagePath('enterprise-add-on.svg'),
  };

  constructor(
    readonly elementRef:ElementRef,
    protected I18n:I18nService,
    protected bannersService:BannersService,
    protected opModalService:OpModalService,
    readonly injector:Injector,
    readonly pathHelper:PathHelperService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    this.link = this.bannersService.getEnterPriseEditionUrl({ referrer: this.opReferrer });
    this.collapsed = this.collapsible;
  }

  toggleCollapse():void {
    this.collapsed = !this.collapsed;
  }
}
