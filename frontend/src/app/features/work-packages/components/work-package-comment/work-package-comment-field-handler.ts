import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { Directive, ElementRef, Injector, OnInit } from '@angular/core';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { Subject } from 'rxjs';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Directive()
export abstract class WorkPackageCommentFieldHandler extends EditFieldHandler implements OnInit {
  public fieldName = 'comment';

  public handler = this;

  public active = false;

  public inEditMode = false;

  public inFlight = false;

  public change:WorkPackageChangeset;

  // Destroy events
  public onDestroy = new Subject<void>();

  constructor(protected elementRef:ElementRef,
    protected injector:Injector) {
    super();
  }

  public ngOnInit() {
    this.change = new WorkPackageChangeset(this.workPackage);
  }

  /**
   * Handle saving the comment
   */
  public abstract handleUserSubmit():Promise<any>;

  public abstract get workPackage():WorkPackageResource;

  public reset(withText = '') {
    if (withText.length > 0) {
      withText += '\n';
    }

    this.change.setValue('comment', { raw: withText });
  }

  public get schema():IFieldSchema {
    return {
      name: I18n.t('js.label_comment'),
      writable: true,
      required: false,
      type: '_comment',
      hasDefault: false,
    };
  }

  public get rawComment() {
    return _.get(this.commentValue, 'raw', '');
  }

  public get commentValue() {
    return this.change.value<{ raw:string }>('comment');
  }

  public handleUserCancel() {
    this.deactivate(true);
  }

  public activate(withText?:string) {
    this.active = true;
    this.reset(withText);
  }

  deactivate(focus:boolean):void {
    this.active = false;
    this.onDestroy.next();
    this.onDestroy.complete();
  }

  focus():void {
    const trigger = this.elementRef.nativeElement.querySelector('.inplace-editing--trigger-container');
    trigger && trigger.focus();
  }

  handleUserKeydown(event:JQuery.TriggeredEvent, onlyCancel?:boolean):void {
  }

  isChanged():boolean {
    return false;
  }

  stopPropagation(evt:JQuery.TriggeredEvent):boolean {
    return false;
  }
}
