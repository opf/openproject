import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  HostBinding,
  ElementRef,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

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
}

export const sidemenuSelector = 'op-sidemenu';

@Component({
  selector: sidemenuSelector,
  templateUrl: './sidemenu.component.html',
  styleUrls: ['./sidemenu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpSidemenuComponent {
  @HostBinding('class.op-sidemenu') className = true;

  @Input() items:IOpSidemenuItem[] = [];

  @Input() title:string;

  @Input() collapsible = false;

  @Input() searchable = false;

  public collapsed = false;

  constructor(
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) {
  }

  toggleCollapsed():void {
    this.collapsed = !this.collapsed;
  }
}
