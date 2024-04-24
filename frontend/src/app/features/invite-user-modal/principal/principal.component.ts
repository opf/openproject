import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { HttpClient } from '@angular/common/http';
import {
  AbstractControl,
  UntypedFormControl,
  UntypedFormGroup,
  Validators,
} from '@angular/forms';
import { take } from 'rxjs/internal/operators/take';
import { map } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DynamicFormComponent } from 'core-app/shared/components/dynamic-forms/components/dynamic-form/dynamic-form.component';
import {
  PrincipalData,
  PrincipalLike,
} from 'core-app/shared/components/principal/principal-types';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { PrincipalType } from '../invite-user.component';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';

function extractCustomFieldsFromSchema(schema:IOPFormSettings['_embedded']['schema']) {
  return Object.keys(schema)
    .reduce((fields, name) => {
      if (name.startsWith('customField') && schema[name].required) {
        return {
          ...fields,
          [name]: schema[name],
        };
      }

      return fields;
    }, {});
}

@Component({
  selector: 'op-ium-principal',
  templateUrl: './principal.component.html',
  styleUrls: ['./principal.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PrincipalComponent implements OnInit {
  @Input() principalData:PrincipalData;

  @Input() project:ProjectResource;

  @Input() type:PrincipalType;

  @Input() roleData:RoleResource;

  @Input() messageData = '';

  @Output() close = new EventEmitter<void>();

  @Output() save = new EventEmitter<{
    principalData:PrincipalData,
    isAlreadyMember:boolean,
    role:RoleResource,
    message:string
  }>();

  @Output() back = new EventEmitter();

  @ViewChild(DynamicFormComponent) dynamicForm:DynamicFormComponent;

  public PrincipalType = PrincipalType;

  public text = {
    principal: {
      title: ():string => this.I18n.t('js.invite_user_modal.title.invite'),
      label: {
        User: this.I18n.t('js.invite_user_modal.principal.label.name_or_email'),
        PlaceholderUser: this.I18n.t('js.invite_user_modal.principal.label.name'),
        Group: this.I18n.t('js.invite_user_modal.principal.label.name'),
        Email: this.I18n.t('js.label_email'),
      },
      change: this.I18n.t('js.label_change'),
      inviteUser: this.I18n.t('js.invite_user_modal.principal.invite_user'),
      createNewPlaceholder: this.I18n.t('js.invite_user_modal.principal.create_new_placeholder'),
      required: {
        User: this.I18n.t('js.invite_user_modal.principal.required.user'),
        PlaceholderUser: this.I18n.t('js.invite_user_modal.principal.required.placeholder'),
        Group: this.I18n.t('js.invite_user_modal.principal.required.group'),
      },
      backButton: this.I18n.t('js.invite_user_modal.back'),
      nextButton: this.I18n.t('js.invite_user_modal.principal.next_button'),
      cancelButton: this.I18n.t('js.button_cancel'),
    },
    role: {
      label: ():string => this.I18n.t('js.invite_user_modal.role.label', {
        project: this.project?.name,
      }),
      description: ():string => this.I18n.t('js.invite_user_modal.role.description', {
        principal: this.principal?.name,
      }),
      required: this.I18n.t('js.invite_user_modal.role.required'),
    },
    message: {
      label: this.I18n.t('js.invite_user_modal.message.label'),
      description: ():string => this.I18n.t('js.invite_user_modal.message.description', {
        principal: this.principal?.name,
      }),
    },
  };

  public principalForm = new UntypedFormGroup({
    // eslint-disable-next-line @typescript-eslint/unbound-method
    principal: new UntypedFormControl(null, [Validators.required]),
    userDynamicFields: new UntypedFormGroup({}),
    // eslint-disable-next-line @typescript-eslint/unbound-method
    role: new UntypedFormControl(null, [Validators.required]),
    message: new UntypedFormControl(''),
  });

  public userDynamicFieldConfig:{
    payload:IOPFormSettings['_embedded']['payload']|null,
    schema:IOPFormSettings['_embedded']['schema']|null,
  } = {
    payload: null,
    schema: null,
  };

  get messageControl():AbstractControl|null {
    return this.principalForm.get('message');
  }

  get roleControl():AbstractControl|null {
    return this.principalForm.get('role');
  }

  get principalControl():AbstractControl|null {
    return this.principalForm.get('principal');
  }

  get principal():PrincipalLike|undefined {
    return this.principalControl?.value as PrincipalLike|undefined;
  }

  get role():RoleResource|undefined {
    return this.roleControl?.value as RoleResource|undefined;
  }

  get message():string|undefined {
    return this.messageControl?.value as string|undefined;
  }

  get dynamicFieldsControl():AbstractControl|null {
    return this.principalForm.get('userDynamicFields');
  }

  get customFields():{ [key:string]:any } {
    return this.dynamicFieldsControl?.value;
  }

  get hasPrincipalSelected():boolean {
    return !!this.principal;
  }

  get textLabel():string {
    if (this.type === PrincipalType.User && this.isNewPrincipal) {
      return this.text.principal.label.Email;
    }
    return this.text.principal.label[this.type];
  }

  get isNewPrincipal():boolean {
    return this.hasPrincipalSelected && !(this.principal instanceof HalResource);
  }

  get isMemberOfCurrentProject():boolean {
    return !!this.principalControl?.value?.memberships?.elements?.find((mem:any) => mem.project.id === this.project.id);
  }

  constructor(
    readonly I18n:I18nService,
    readonly httpClient:HttpClient,
    readonly apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
  ) {}

  ngOnInit():void {
    this.principalControl?.setValue(this.principalData.principal);
    this.roleControl?.setValue(this.roleData);
    this.messageControl?.setValue(this.messageData);

    if (this.type === PrincipalType.User) {
      const payload = this.isNewPrincipal ? this.principalData.customFields : {};
      this
        .apiV3Service
        .users
        .form
        .post(payload)
        .pipe(
          take(1),
          // The subsequent code expects to not work with a HalResource but rather with the raw
          // api response.
          map((formResource) => formResource.$source),
        )
        .subscribe((formConfig) => {
          this.userDynamicFieldConfig.schema = extractCustomFieldsFromSchema(formConfig._embedded?.schema);
          this.userDynamicFieldConfig.payload = formConfig._embedded?.payload;
          this.cdRef.detectChanges();
        });
    }
  }

  createNewFromInput(input:PrincipalLike):void {
    this.principalControl?.setValue(input);
  }

  onSubmit($e:Event):void {
    $e.preventDefault();

    if (this.dynamicForm) {
      this.dynamicForm.validateForm().subscribe(() => {
        this.onValidatedSubmit();
      });
    } else {
      this.onValidatedSubmit();
    }
  }

  onValidatedSubmit():void {
    if (this.principalForm.invalid) {
      return;
    }

    // The code below transforms the model value as it comes from the dynamic form to the value accepted by the API.
    // This is not just necessary for submit, but also so that we can reseed the initial values to the payload
    // when going back to this step after having completed it once.
    const fieldsSchema = this.userDynamicFieldConfig.schema || {};
    const customFields = Object.keys(fieldsSchema)
      .reduce((result, fieldKey) => {
        const fieldSchema = fieldsSchema[fieldKey];
        let fieldValue = this.customFields[fieldKey];

        if (fieldSchema.location === '_links') {
          fieldValue = Array.isArray(fieldValue)
            ? fieldValue.map((opt:any) => (opt._links ? opt._links.self : opt))
            : (fieldValue._links ? fieldValue._links.self : fieldValue);
        }

        result = {
          ...result,
          [fieldKey]: fieldValue,
        };

        return result;
      }, {});

    this.save.emit({
      principalData: {
        customFields,
        principal: this.principal as PrincipalLike,
      },
      isAlreadyMember: this.isMemberOfCurrentProject,
      role: this.role as RoleResource,
      message: this.message as string,
    });
  }
}
