import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  HostBinding,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface IOpSidemenuItem {
  title:string;
  icon?:string;
  count?:number;
  href?:string;
  uiSref?:string;
  uiParams?:unknown;
  children?:IOpSidemenuItem[];
  collapsible?:boolean;
}

@Component({
  selector: 'op-sidemenu',
  templateUrl: './sidemenu.component.html',
  styleUrls: ['./sidemenu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpSidemenuComponent {
  @HostBinding('class.op-sidemenu') className = true;

  @Input() items:IOpSidemenuItem[] = [];

  @Input() title:string;

  @Input() collapsible = false;

  public collapsed = false;

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) {
  }

  toggleCollapsed():void {
    this.collapsed = !this.collapsed;
  }
}
