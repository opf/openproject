import { ChangeDetectionStrategy, Component, ElementRef, Input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { contactUrl, pricingUrl } from 'core-app/core/setup/globals/constants.const';


@Component({
  selector: 'op-enterprise-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './enterprise-page.component.html',
})
export class EnterprisePageComponent {
  @Input() public feature_more_info:string;

  @Input() public feature_video:string;

  @Input() public feature_image:string;

  @Input() public feature_title:string;

  @Input() public feature_description:string;

  @Input() public more_info:string;

  @Input() public hide_breadcrumb = false;

  text = {
    button_contact_us: this.I18n.t('js.admin.enterprise.upsale.button_contact_us'),
    upgrade: this.I18n.t('js.admin.enterprise.upsale.button_upgrade'),
    upgrade_link: pricingUrl,
    contact_link: contactUrl.en,
    benefits_description: this.I18n.t('js.admin.enterprise.upsale.benefits.description'),
    premium_features_text: this.I18n.t('js.admin.enterprise.upsale.benefits.premium_features_text'),
    professional_support_text: this.I18n.t('js.admin.enterprise.upsale.benefits.professional_support_text'),
    enterprise_info_html: (feature_title:string):string => this.I18n.t('js.admin.enterprise.upsale.enterprise_info_html', {
      feature_title,
    }),
    upgrade_info: this.I18n.t('js.admin.enterprise.upsale.upgrade_info'),
    button_contact: this.I18n.t('js.admin.enterprise.upsale.buttons.contact'),
    button_upgrade: this.I18n.t('js.admin.enterprise.upsale.buttons.upgrade'),
  };

  image = {
    enterprise_edition: imagePath('enterprise-add-on.svg'),
  };

  constructor(
    readonly elementRef:ElementRef,
    protected I18n:I18nService,
    readonly pathHelper:PathHelperService,
  ) {

  }
}
