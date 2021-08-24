import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { ElementRef, Injectable, Injector } from '@angular/core';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { BehaviorSubject } from 'rxjs';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { UploadFile } from 'core-app/core/file-upload/op-file-upload.service';
import { ICKEditorContext } from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';

@Injectable()
export class CustomTextEditFieldService extends EditFieldHandler {
  public fieldName = 'text';

  public valueChanged$:BehaviorSubject<string>;

  public changeset:ResourceChangeset;

  public active:boolean;

  constructor(protected elementRef:ElementRef,
    protected injector:Injector,
    protected halResource:HalResourceService,
    protected schemaCache:SchemaCacheService) {
    super();
  }

  onFocusOut():void {
    // interface
  }

  public initialize(value:GridWidgetResource) {
    this.initializeChangeset(value);
    this.valueChanged$ = new BehaviorSubject(value.options.text as string);
  }

  public reinitialize(value:GridWidgetResource) {
    this.initializeChangeset(value);
  }

  /**
   * Handle saving the text
   */
  public handleUserSubmit():Promise<any> {
    return this.update();
  }

  public reset(withText = '') {
    let resetText:string = withText;
    if (withText.length > 0) {
      resetText += '\n';
    }

    this.changeset.setValue(this.fieldName, { raw: resetText });
  }

  public get schema():IFieldSchema {
    return {
      name: I18n.t('js.grid.widgets.custom_text.title'),
      writable: true,
      required: false,
      type: 'Formattable',
      hasDefault: false,
    };
  }

  private async update() {
    return this
      .onSubmit()
      .then(() => {
        this.valueChanged$.next(this.rawText);
        this.deactivate();
      });
  }

  public get rawText() {
    return _.get(this.textValue, 'raw', '');
  }

  public get htmlText() {
    return _.get(this.textValue, 'html', '');
  }

  public get textValue() {
    return this.changeset.value(this.fieldName);
  }

  public handleUserCancel() {
    this.deactivate();
  }

  deactivate():void {
    this.changeset.clear();
    this.active = false;
  }

  activate() {
    this.active = true;
  }

  get inEditMode():boolean {
    return false;
  }

  get inFlight():boolean {
    return this.changeset.inFlight;
  }

  focus():void {
    const trigger = this.elementRef.nativeElement.querySelector('.inplace-editing--trigger-container');
    if (trigger) {
      trigger.focus();
    }
  }

  setErrors():void {
    // interface
  }

  handleUserKeydown():void {
    // interface
  }

  isChanged():boolean {
    return !this.changeset.isEmpty();
  }

  stopPropagation():boolean {
    return false;
  }

  /**
   * Mimiks having a HalResource for the sake of the Changeset.
   * @param value
   */
  private initializeChangeset(value:GridWidgetResource) {
    const schemaHref = 'customtext-schema';
    const resourceSource = {
      text: value.options.text,
      getEditorContext: () => ({
        type: 'full',
        macros: 'resource',
      } as ICKEditorContext),
      canAddAttachments: value.grid.canAddAttachments,
      uploadAttachments: (files:UploadFile[]) => value.grid.uploadAttachments(files),
      _links: {
        schema: {
          href: schemaHref,
        },
      },
    };

    const resource = this.halResource.createHalResource(resourceSource, true);

    const schemaSource = {
      text: this.schema,
      _links: {
        self: { href: schemaHref },
      },
    };

    const schema:SchemaResource = this.halResource.createHalResource(schemaSource, true);

    this.schemaCache.update(resource, schema);

    this.changeset = new ResourceChangeset(resource);
  }
}
