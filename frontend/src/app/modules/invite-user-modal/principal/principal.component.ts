import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
} from '@angular/core';
import { HttpClient } from "@angular/common/http";
import {
  FormGroup,
  FormControl,
  Validators,
} from '@angular/forms';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { PrincipalLike } from "core-app/modules/principal/principal-types";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { PrincipalType } from '../invite-user.component';

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
  @Input('principal') storedPrincipal:PrincipalLike|null = null;
  @Input() project:ProjectResource;
  @Input() type:PrincipalType;

  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<{ principal:PrincipalLike, isAlreadyMember:boolean }>();
  @Output() back = new EventEmitter();

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
    },
    changeUserSelection: this.I18n.t('js.invite_user_modal.principal.change_user_selection'),
    changePlaceholderSelection: this.I18n.t('js.invite_user_modal.principal.change_placeholder_selection'),
    changeGroupSelection: this.I18n.t('js.invite_user_modal.principal.change_group_selection'),
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
    userDynamicFields: new FormControl(null),
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

  get hasPrincipalSelected() {
    return !!this.principal;
  }

  get isNewPrincipal() {
    console.log(this.hasPrincipalSelected, !(this.principal instanceof HalResource), this.type);
    return this.hasPrincipalSelected && !(this.principal instanceof HalResource);
  }

  get isMemberOfCurrentProject() {
    return !!this.principalControl?.value?.memberships?.elements?.find((mem:any) => mem.project.id === this.project.id);
  }

  constructor(
    readonly I18n:I18nService,
    readonly httpClient:HttpClient,
  ) {}

  ngOnInit() {
    this.principalControl?.setValue(this.storedPrincipal);

    this.httpClient
      .post<IOPFormSettings>('/api/v3/users/form', {}, { withCredentials: true, responseType: 'json' })
      .subscribe((formConfig) => {
        this.userDynamicFieldConfig.schema = extractCustomFieldsFromSchema(formConfig._embedded?.schema);
        this.userDynamicFieldConfig.payload = formConfig._embedded?.payload;
      });
  }

  createNewFromInput(input:PrincipalLike) {
    this.principalControl?.setValue(input);
  }

  onSubmit($e:Event) {
    $e.preventDefault();

    if (this.isNewPrincipal && this.type === PrincipalType.User) {
      return this.httpClient
        .post<IOPFormSettings>(
          '/api/v3/users/form',
          this.principalForm.get('userDynamicFields')?.value, { withCredentials: true, responseType: 'json' })
        .subscribe((formConfig) => {
          console.log(formConfig);

        });
    }

    if (this.principalForm.invalid) {
      return;
    }

    this.save.emit({
      principal: this.principal!,
      isAlreadyMember: this.isMemberOfCurrentProject,
    });
  }
}
