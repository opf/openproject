import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {ElementRef, Injector, OnInit} from "@angular/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {Subject} from "rxjs";
import {WorkPackageChange} from "core-components/wp-edit/work-package-change";

class CommentChange extends WorkPackageChange {
  public comment:{raw:string};
}

export abstract class WorkPackageCommentFieldHandler extends EditFieldHandler implements OnInit {
  public fieldName = 'comment';
  public handler = this;
  public inEdit = false;
  public inEditMode = false;
  public inFlight = false;

  public change:CommentChange;

  // Destroy events
  public onDestroy = new Subject<void>();

  constructor(protected elementRef:ElementRef,
              protected injector:Injector) {
    super();
  }

  public ngOnInit() {
    this.change = new CommentChange(this.workPackage);
  }

  /**
   * Handle saving the comment
   */
  public abstract handleUserSubmit():Promise<any>;

  /**
   * Required HTML id for the edit field
   */
  public abstract get htmlId():string;

  /**
   * Required field label translation
   */
  public abstract get fieldLabel():string;

  public abstract get workPackage():WorkPackageResource;

  public reset(withText:string = '') {
    if (withText.length > 0) {
      withText += '\n';
    }

    this.change.comment = { raw: withText };
  }

  public get schema():IFieldSchema {
    return {
      name: I18n.t('js.label_comment'),
      writable: true,
      required: false,
      type: '_comment',
      hasDefault: false
    }
  }

  public get rawComment() {
    return _.get(this.commentValue, 'raw', '');
  }

  public get commentValue() {
    return this.change.comment;
  }

  public handleUserCancel() {
    this.deactivate(true);
  }

  public get active() {
    return this.inEdit;
  }

  public activate(withText?:string) {
    this.inEdit = true;
    this.reset(withText);
  }

  deactivate(focus:boolean):void {
    this.inEdit = false;
    this.onDestroy.next();
    this.onDestroy.complete();
  }

  focus():void {
    const trigger = this.elementRef.nativeElement.querySelector('.inplace-editing--trigger-container');
    trigger && trigger.focus();
  }

  handleUserKeydown(event:JQueryEventObject, onlyCancel?:boolean):void {
  }

  isChanged():boolean {
    return false;
  }

  stopPropagation(evt:JQueryEventObject):boolean {
    return false;
  }
}
