import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import {
  ApplicationRef,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  OnChanges,
  OnDestroy,
  OnInit,
  SimpleChanges,
  ViewChild,
} from '@angular/core';
import {
  CustomTextEditFieldService,
} from 'core-app/shared/components/grids/widgets/custom-text/custom-text-edit-field.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { filter } from 'rxjs/operators';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  templateUrl: './custom-text.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CustomTextEditFieldService,
  ],
})
export class WidgetCustomTextComponent extends AbstractWidgetComponent implements OnInit, OnChanges, OnDestroy {
  protected currentRawText:string;

  public customText:SafeHtml;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
  };

  @ViewChild('displayContainer') readonly displayContainer:ElementRef;

  constructor(
    protected I18n:I18nService,
    protected injector:Injector,
    public handler:CustomTextEditFieldService,
    protected cdr:ChangeDetectorRef,
    protected sanitization:DomSanitizer,
    protected appRef:ApplicationRef,
    protected layout:GridAreaService,
  ) {
    super(I18n, injector);
  }

  ngOnInit():void {
    this.setupVariables(true);

    this
      .handler
      .valueChanged$
      .pipe(
        this.untilDestroyed(),
        filter((value) => value !== this.resource.options.text),
      ).subscribe((newText) => {
      const changeset = this.setChangesetOptions({ text: { raw: newText } });
      this.resourceChanged.emit(changeset);
    });
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.resource.currentValue.options.text.raw !== this.currentRawText) {
      this.setupVariables();

      this.cdr.detectChanges();
    }
  }

  public activate(event:MouseEvent) {
    // Prevent opening the edit mode if a link was clicked
    if (this.clickedElementIsLinkWithinDisplayContainer(event)) {
      return;
    }

    // Load the attachments so that they are displayed in the list.
    // Once that is done, we can show the edit form.
    void this.resource.grid.updateAttachments().then(() => {
      this.handler.activate();
      this.cdr.detectChanges();
    });
  }

  public get placeholderText() {
    return this.I18n.t('js.grid.widgets.work_packages_overview.placeholder');
  }

  public get inplaceEditClasses() {
    let classes = 'inplace-editing--container inline-edit--display-field -editable';

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
    return !this.currentRawText.length;
  }

  public get isTextEditable() {
    return this.layout.isEditable;
  }

  private setupVariables(initial = false) {
    this.memorizeRawText();
    if (initial) {
      this.handler.initialize(this.resource);
    } else {
      this.handler.reinitialize(this.resource);
    }
    this.memorizeCustomText();
  }

  private memorizeRawText() {
    this.currentRawText = (this.resource.options.text as HalResource).raw;
  }

  private memorizeCustomText() {
    this.customText = this.sanitization.bypassSecurityTrustHtml(this.handler.htmlText);
  }

  private clickedElementIsLinkWithinDisplayContainer(event:any) {
    return this.displayContainer.nativeElement.contains(event.target.closest('a,macro'));
  }
}
