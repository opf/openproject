import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  HostBinding,
  ElementRef,
} from '@angular/core';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export interface IOpSidemenuItem {
  title:string;
  icon?:string;
  count?:number;
  href?:string;
  uiSref?:string;
  uiParams?:unknown;
  uiOptions?:unknown;
  children?:IOpSidemenuItem[];
  collapsible?:boolean;
  isEnterprise?:boolean;
}

export const sidemenuSelector = 'op-sidemenu';

@Component({
  selector: sidemenuSelector,
  templateUrl: './sidemenu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpSidemenuComponent {
  @HostBinding('class.op-sidemenu') className = true;

  @Input() items:IOpSidemenuItem[] = [];

  @Input() title:string;

  @Input() collapsible = false;

  @Input() searchable = false;

  public collapsed = false;

  noEEToken = this.Banner.eeShowBanners;

  constructor(
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly Banner:BannersService,
  ) {
    populateInputsFromDataset(this);
  }

  toggleCollapsed():void {
    this.collapsed = !this.collapsed;
  }
}
