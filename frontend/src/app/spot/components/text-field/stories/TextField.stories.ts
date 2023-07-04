import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';
import { SpotTextFieldComponent } from '../text-field.component';

const meta:Meta = {
  title: 'Components/TextField',
  component: SpotTextFieldComponent,
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Default:Story = {
  args: {
    value: '',
    disabled: false,
    placeholder: '',
    showClearButton: true,
    name: 'my-input',
  },
};

export const SearchWithIcon:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-text-field>
        <span
          class="spot-icon spot-icon_search"
          slot="before"
        ></span>
      </spot-text-field>
   `,
  }),
};

export const SearchWithIconAndValue:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-text-field value="Some value">
        <span
          class="spot-icon spot-icon_search"
          slot="before"
        ></span>
      </spot-text-field>
   `,
  }),
};

export const Placeholder:Story = {
  args: {
    placeholder: 'Enter a value here',
  },
};

export const WithValue:Story = {
  args: {
    value: 'Some value',
  },
};

export const Disabled:Story = {
  args: {
    disabled: true,
  },
};

export const DisabledWithValue:Story = {
  args: {
    value: 'Disabled with value',
    disabled: true,
  },
};
