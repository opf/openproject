import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface IOpCollapsibleMenuItem {
  title:string;
  icon?:string;
  counter?:number;
  link:string;
}

@Component({
  selector: 'op-collapsible-menu',
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpCollapsibleMenuComponent implements OnInit {
  @Input() items:IOpCollapsibleMenuItem[];

  @Input() title:string;

  collapsed = false;

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) { }

  ngOnInit() {
  }
}
