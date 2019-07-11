import {HostBinding, Input, EventEmitter, Output, HostListener} from "@angular/core";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export abstract class AbstractWidgetComponent {
  @HostBinding('style.grid-column-start') gridColumnStart:number;
  @HostBinding('style.grid-column-end') gridColumnEnd:number;
  @HostBinding('style.grid-row-start') gridRowStart:number;
  @HostBinding('style.grid-row-end') gridRowEnd:number;

  @Input() resource:GridWidgetResource;

  @Output() resourceChanged = new EventEmitter<GridWidgetResource>();

  public get widgetName() {
    return this.resource.options.name;
  }

  public renameWidget(name:string) {
    this.resource.options.name = name;

    this.resourceChanged.emit(this.resource);
  }

  constructor(protected i18n:I18nService) { }

  // apparently, static methods cannot be abstract
  // https://github.com/microsoft/TypeScript/issues/14600
  public static get identifier():string {
    return 'need to override';
  }
}
