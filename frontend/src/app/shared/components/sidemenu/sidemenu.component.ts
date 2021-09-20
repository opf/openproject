import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnInit,
  HostBinding,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface IOpSidemenuItem {
  title:string;
  icon?:string;
  counter?:number;
  link:string;
  children?: IOpSidemenuItem[];
}

@Component({
  selector: 'op-sidemenu',
  templateUrl: './sidemenu.component.html',
  styleUrls: ['./sidemenu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpSidemenuComponent implements OnInit {
  @HostBinding('class.op-sidemenu') className = true;
  @HostBinding('class.op-sidemenu_collapsed') collapsed = false;

  @Input() items:IOpSidemenuItem[] = [];

  @Input() title:string;

  @Input() collapsible:string;

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) { }

  ngOnInit() {
    console.log(this.items);
  }

  toggleCollapsed() {
    this.collapsed = !this.collapsed;
  }
}
