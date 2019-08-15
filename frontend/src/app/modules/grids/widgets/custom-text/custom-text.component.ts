import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, ChangeDetectionStrategy, Injector, OnInit, OnDestroy, SimpleChanges, ChangeDetectorRef} from '@angular/core';
import {CustomTextEditFieldService} from "core-app/modules/grids/widgets/custom-text/custom-text-edit-field.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {filter} from 'rxjs/operators';

@Component({
  templateUrl: './custom-text.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CustomTextEditFieldService
  ]
})
export class WidgetCustomTextComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  protected currentRawText:string;

  constructor (protected i18n:I18nService,
               protected injector:Injector,
               public handler:CustomTextEditFieldService,
               protected cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit():void {
    this.memorizeRawText();
    this.handler.initialize(this.resource);

    this
      .handler
      .valueChanged$
      .pipe(
        untilComponentDestroyed(this),
        filter(value => value !== this.resource.options['text'])
      ).subscribe(newText => {
        let changeset = this.setChangesetOptions({ text: { raw: newText } });
        this.resourceChanged.emit(changeset);
      });
  }

  ngOnDestroy():void {
    // comply to interface
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.resource.currentValue.options.text.raw !== this.currentRawText) {
      this.memorizeRawText();
      this.handler.reinitialize(this.resource);
      this.cdr.detectChanges();
    }
  }

  public activate() {
    // load the attachments so that they are displayed in the list;
    this.resource.grid.updateAttachments();

    this.handler.activate();
  }

  public get customText() {
    return this.handler.htmlText;
  }

  public get placeholderText() {
    return this.i18n.t('js.grid.widgets.work_packages_overview.placeholder');
  }

  public get inplaceEditClasses() {
    let classes = 'inplace-editing--container wp-edit-field--display-field';

    if (this.textEmpty) {
      classes += ' -placeholder';
    }

    return classes;
  }

  public get schema() {
    return this.handler.schema;
  }

  public get changeset() {
    return this.handler.changeset;
  }

  public get active() {
    return this.handler.active;
  }

  public get textEmpty() {
    return !this.customText;
  }

  private memorizeRawText() {
    this.currentRawText = (this.resource.options.text as HalResource).raw;
  }
}
