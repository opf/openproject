import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewChild,
  ChangeDetectorRef,
} from '@angular/core';
import { HttpClient } from "@angular/common/http";
import {
  FormGroup,
  FormControl,
  Validators,
} from '@angular/forms';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { PrincipalData, PrincipalLike } from "core-app/modules/principal/principal-types";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { DynamicFormComponent } from "core-app/modules/common/dynamic-forms/components/dynamic-form/dynamic-form.component"
import { PrincipalType } from '../invite-user.component';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { take } from 'rxjs/internal/operators/take';
import { map } from 'rxjs/operators';

function extractCustomFieldsFromSchema(schema: IOPFormSettings['_embedded']['schema']) {
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
})
export class PrincipalComponent implements OnInit {
  @Input() principalData:PrincipalData;
  @Input() project:ProjectResource;
  @Input() type:PrincipalType;

  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<{ principalData:PrincipalData, isAlreadyMember:boolean }>();
  @Output() back = new EventEmitter();

  @ViewChild(DynamicFormComponent) dynamicForm: DynamicFormComponent;

  public PrincipalType = PrincipalType;

  public text = {
    title: () => this.I18n.t('js.invite_user_modal.title.invite_to_project', {
      type: this.I18n.t(`js.invite_user_modal.title.${this.type}`),
      project: this.project.name,
    }),
    label: {
      User: this.I18n.t('js.invite_user_modal.principal.label.name_or_email'),
      PlaceholderUser: this.I18n.t('js.invite_user_modal.principal.label.name'),
      Group: this.I18n.t('js.invite_user_modal.principal.label.name'),
      Email: this.I18n.t('js.label_email')
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
  };

  public principalForm = new FormGroup({
    principal: new FormControl(null, [ Validators.required ]),
    userDynamicFields: new FormGroup({}),
  });

  public userDynamicFieldConfig: {
    payload: IOPFormSettings['_embedded']['payload']|null,
    schema: IOPFormSettings['_embedded']['schema']|null,
  } = {
    payload: null,
    schema: null,
  };

  get principalControl() {
    return this.principalForm.get('principal');
  }

  get principal():PrincipalLike|undefined {
    return this.principalControl?.value;
  }

  get dynamicFieldsControl() {
    return this.principalForm.get('userDynamicFields');
  }

  get customFields():{[key:string]:any} {
    return this.dynamicFieldsControl?.value;
  }

  get hasPrincipalSelected() {
    return !!this.principal;
  }

  get textLabel() {
    if (this.type === PrincipalType.User && this.isNewPrincipal) {
      return this.text.label.Email;
    } else {
      return this.text.label[this.type];
    }
  }

  get isNewPrincipal() {
    return this.hasPrincipalSelected && !(this.principal instanceof HalResource);
  }

  get isMemberOfCurrentProject() {
    return !!this.principalControl?.value?.memberships?.elements?.find((mem:any) => mem.project.id === this.project.id);
  }

  constructor(
    readonly I18n:I18nService,
    readonly httpClient:HttpClient,
    readonly apiV3Service:APIV3Service,
    readonly cdRef: ChangeDetectorRef,
  ) {}

  ngOnInit() {
    this.principalControl?.setValue(this.principalData.principal);

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
          map(formResource => formResource.$source)
        )
        .subscribe((formConfig) => {
          this.userDynamicFieldConfig.schema = extractCustomFieldsFromSchema(formConfig._embedded?.schema);
          this.userDynamicFieldConfig.payload = formConfig._embedded?.payload;
          this.cdRef.detectChanges();
        });
    }
  }

  createNewFromInput(input:PrincipalLike) {
    this.principalControl?.setValue(input);
  }

  onSubmit($e:Event) {
    $e.preventDefault();

    if (this.dynamicForm) {
      this.dynamicForm.validateForm().subscribe(() => {
        this.onValidatedSubmit();
      });
    } else {
      this.onValidatedSubmit();
    }
  }

  onValidatedSubmit() {
    if (this.principalForm.invalid) {
      return;
    }

    // The code below transforms the model value as it comes from the dynamic form to the value accepted by the API.
    // This is not just necessary for submit, but also so that we can reseed the initial values to the payload
    // when going back to this step after having completed it once.
    const links = this.customFields!._links || {};
    const customFields = {
      ...this.customFields!,
      _links: Object.keys(links).reduce((cfs, name) => ({
        ...cfs,
        [name]: Array.isArray(links[name])
          ? links[name].map((opt: any) => opt._links ? opt._links.self : opt)
          : (links[name]._links ? links[name]._links.self : links[name])
      }), {}),
    };

    this.save.emit({
      principalData: {
        customFields,
        principal: this.principal!,
      },
      isAlreadyMember: this.isMemberOfCurrentProject,
    });
  }
}
