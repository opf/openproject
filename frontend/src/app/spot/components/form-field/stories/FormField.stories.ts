import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import {
  UntypedFormControl,
  UntypedFormGroup,
  Validators,
} from '@angular/forms';
import { ReactiveFormsModule } from '@angular/forms';

import { I18nService } from '../../../../core/i18n/i18n.service';
import { I18nServiceStub } from '../../../../../stories/i18n.service.stub';

import { OpSpotModule } from '../../../spot.module';

import { SpotFormFieldComponent } from '../form-field.component';

const meta:Meta = {
  title: 'Patterns/FormField',
  component: SpotFormFieldComponent,
  decorators: [
    moduleMetadata({
      imports: [
        OpSpotModule,
        ReactiveFormsModule,
      ],
      providers: [
        {
          provide: I18nService,
          useFactory: () => I18nServiceStub,
        },
      ],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const InputSlot:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-form-field label="Form field with input">
        <spot-text-field slot="input"></spot-text-field>
      </spot-form-field>
   `,
  }),
};

export const DescriptionSlot:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-form-field label="Form field with description">
        <spot-text-field slot="input"></spot-text-field>
        <span slot="description">
          Helpful guidelines so the user can be confident about their input.
        </span>
      </spot-form-field>
   `,
  }),
};

export const BasicValidation:Story = {
  render: (args) => ({
    props: {
      ...args,
      myForm: new UntypedFormGroup({
        myInput: new UntypedFormControl(null, [Validators.required, Validators.minLength(8)]),
      }),
      onSubmit: (event:any) => console.log('onSubmit', event),
    },
    template: `
      <form
        [formGroup]="myForm"
        (ngSubmit)="onSubmit($event)"
        class="spot-container"
      >
        <spot-form-field
          label="Form field with validation"
          [required]="true"
        >
          <spot-text-field
            formControlName="myInput"
            slot="input"
          ></spot-text-field>

          <div
            slot="errors"
            class="spot-form-field--error"
            *ngIf="myForm.get('myInput')!.errors?.required"
          >
            This input is required.
          </div>

          <div
            slot="errors"
            class="spot-form-field--error"
            *ngIf="myForm.get('myInput')!.errors?.minlength"
          >
            This input needs to be at least 8 characters long.
          </div>
        </spot-form-field>

        <div class="spot-action-bar">
          <div class="spot-action-bar--right">
            <button
              type="submit"
              class="button -highlight spot-action-bar--action"
            >Submit data</button>
          </div>
        </div>
      </form>
   `,
  }),
};

export const ActionSlot:Story = {
  render: (args) => ({
    props: {
      ...args,
      alert: (s:string) => console.log(s),
    },
    template: `
      <spot-form-field label="Form field with input">
        <spot-text-field slot="input"></spot-text-field>
        <button
          type="button"
          (click)="log('Some action')"
          class="spot-link"
          slot="action"
        >Some action</button>
        <button
          type="button"
          (click)="log('Another action')"
          class="spot-link"
          slot="action"
        >Another action</button>
      </spot-form-field>
   `,
  }),
};
