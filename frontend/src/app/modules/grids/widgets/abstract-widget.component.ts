import {HostBinding, Input} from "@angular/core";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export abstract class AbstractWidgetComponent {
  @HostBinding('style.grid-column-start') gridColumnStart:number;
  @HostBinding('style.grid-column-end') gridColumnEnd:number;
  @HostBinding('style.grid-row-start') gridRowStart:number;
  @HostBinding('style.grid-row-end') gridRowEnd:number;

  @Input() resource:GridWidgetResource;

  constructor(protected i18n:I18nService) { }
}
