import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { I18nService } from '../../../../core/i18n/i18n.service';
import { I18nServiceStub } from '../../../../../stories/i18n.service.stub';

import { OpSpotModule } from '../../../spot.module';

import { SpotSelectorFieldComponent } from '../selector-field.component';

const meta:Meta = {
  title: 'Patterns/SelectorField',
  component: SpotSelectorFieldComponent,
  decorators: [
    moduleMetadata({
      imports: [
        OpSpotModule,
        ReactiveFormsModule,
        FormsModule,
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

export const Default:Story = {
  render: (args) => ({
    props: {
      ...args,
      mixed: null,
    },
    template: `
      <div class="spot-container">
        <spot-selector-field label="With a spot-checkbox">
          <spot-checkbox slot="input"></spot-checkbox>
        </spot-selector-field>

        <spot-selector-field
          label="Reverse label with a spot-checkbox"
          [reverseLabel]="true"
        >
          <spot-checkbox slot="input"></spot-checkbox>
        </spot-selector-field>

        <hr class="spot-divider">

        <spot-selector-field label="With a spot-switch">
          <spot-switch
            slot="input"
            [checked]="false"
          ></spot-switch>
        </spot-selector-field>

        <spot-selector-field
          label="Reverse label with a spot-switch"
          [reverseLabel]="true"
        >
          <spot-switch slot="input"></spot-switch>
        </spot-selector-field>
      </div>
   `,
  }),
};

export const LongLabel:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-selector-field
        label="This is an incredibly long label in the hopes that we'll be able to make it run over multiple lines even on very wide screens, incredibly wide screens that are way past full hd"
      >
        <spot-checkbox slot="input"></spot-checkbox>
      </spot-selector-field>
   `,
  }),
};

export const FontWeight:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-container">
        <spot-selector-field
          label="Bold Label"
          labelWeight="bold"
        >
          <spot-checkbox slot="input"></spot-checkbox>
        </spot-selector-field>

        <spot-selector-field label="Regular Label">
          <spot-checkbox slot="input"></spot-checkbox>
        </spot-selector-field>
      </div>
   `,
  }),
};
