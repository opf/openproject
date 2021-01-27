import {
  Component,
  ElementRef,
  OnInit,
  Input,
  Output,
  EventEmitter,
} from '@angular/core';
import {
  FormGroup,
  FormControl,
  Validators,
} from '@angular/forms';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-principal',
  templateUrl: './principal.component.html',
  styleUrls: ['./principal.component.sass'],
})
export class PrincipalComponent implements OnInit {
  @Input() principal:any = null;
  @Input() project:any = null;
  @Input() type:string = '';

  @Output('close') close = new EventEmitter<void>();
  @Output() save = new EventEmitter<{ principal:any, isAlreadyMember:boolean }>();
  @Output() back = new EventEmitter();

  public text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  public principalForm = new FormGroup({
    principal: new FormControl(null, [ Validators.required ]),
  });

  get principalControl() {
    return this.principalForm.get('principal');
  }

  get isNewPrincipal() {
    return typeof this.principalControl?.value === 'string';
  }

  get isMemberOfCurrentProject() {
    return !!this.principalControl?.value?.memberships?.elements?.find((mem:any) => mem.project.id === this.project.id);
  }

  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {}

  ngOnInit() {
    this.principalControl?.setValue(this.principal);
  }

  createNewFromInput(input:string) {
    this.principalControl?.setValue(input);
  }

  onSubmit($e:Event) {
    $e.preventDefault();

    if (this.principalForm.invalid) {
      this.principalForm.markAllAsTouched();
      return;
    }

    this.save.emit({
      principal: this.principalControl?.value,
      isAlreadyMember: this.isMemberOfCurrentProject,
    });
  }
}
