import {HostBinding, Input, EventEmitter, Output, HostListener, Injector} from "@angular/core";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WidgetChangeset} from "core-app/modules/grids/widgets/widget-changeset";

export abstract class AbstractWidgetComponent {
  @HostBinding('style.grid-column-start') gridColumnStart:number;
  @HostBinding('style.grid-column-end') gridColumnEnd:number;
  @HostBinding('style.grid-row-start') gridRowStart:number;
  @HostBinding('style.grid-row-end') gridRowEnd:number;

  @Input() resource:GridWidgetResource;

  @Output() resourceChanged = new EventEmitter<WidgetChangeset>();

  public get widgetName():string {
    let fallback = this.resource.options.name;
    let widgetIdentifier = this.resource.identifier;
    return this.i18n.t(
      `js.grid.widgets.${widgetIdentifier}.title`,
      { defaultValue: fallback }
    );
  }

  public renameWidget(name:string) {
    let changeset = this.setChangesetOptions({ name: name });

    this.resourceChanged.emit(changeset);
  }

  constructor(protected i18n:I18nService,
              protected injector:Injector) { }

  protected setChangesetOptions(values:{ [key:string]:unknown; }) {
    let changeset = new WidgetChangeset(this.injector, this.resource);

    changeset.setValue('options', Object.assign({}, this.resource.options, values));

    return changeset;
  }
}
