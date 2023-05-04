import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';

const meta:Meta = {
  title: 'Components/Checkbox',
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Basic:Story = {
  render: (args) => ({
    props: args,
    template: `
      <label>
        <spot-checkbox
          [name]="name"
          [disabled]="disabled"
          [checked]="checked"
          (change)="checkedChange"
        ></spot-checkbox>
      </label>
   `,
  }),
};
