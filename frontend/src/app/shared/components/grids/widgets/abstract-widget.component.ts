import { Directive, EventEmitter, HostBinding, Injector, Input, Output, inject } from '@angular/core';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WidgetChangeset } from 'core-app/shared/components/grids/widgets/widget-changeset';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Directive()
export abstract class AbstractWidgetComponent extends UntilDestroyedMixin {
  protected i18n = inject(I18nService);
  protected injector = inject(Injector);

  @HostBinding('style.grid-column-start') gridColumnStart:number;

  @HostBinding('style.grid-column-end') gridColumnEnd:number;

  @HostBinding('style.grid-row-start') gridRowStart:number;

  @HostBinding('style.grid-row-end') gridRowEnd:number;

  @HostBinding('class.grid--widget-host') gridWidgetHost = true;

  @Input() resource:GridWidgetResource;

  @Output() resourceChanged = new EventEmitter<WidgetChangeset>();

  public get widgetName():string {
    const editableName = this.resource?.options.name as string;
    const widgetIdentifier = this.resource?.identifier;

    if (this.isEditable) {
      return editableName;
    }
    return this.i18n.t(
      `js.grid.widgets.${widgetIdentifier}.title`,
      { defaultValue: editableName },
    );
  }

  public renameWidget(name:string) {
    const changeset = this.setChangesetOptions({ name });

    this.resourceChanged.emit(changeset);
  }

  /**
   * By default, all widget titles are editable by the user.
   * We arbitrarily restrict this for some resources however,
   * whose component classes will set this to false.
   */
  // eslint-disable-next-line @typescript-eslint/class-literal-property-style
  public get isEditable() {
    return true;
  }

  constructor() {
    super();
  }

  protected setChangesetOptions(values:Record<string, unknown>) {
    const changeset = new WidgetChangeset(this.resource);

    changeset.setValue('options', { ...this.resource.options, ...values });

    return changeset;
  }
}
