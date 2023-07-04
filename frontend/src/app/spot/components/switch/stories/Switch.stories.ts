import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';
import { SpotSwitchComponent } from '../switch.component';

const meta:Meta = {
  title: 'Components/Switch',
  component: SpotSwitchComponent,
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Checked:Story = {
  args: {
    checked: true,
    disabled: false,
  },
};

export const Unchecked:Story = {
  args: {
    checked: false,
    disabled: false,
  },
};

export const Disabled:Story = {
  args: {
    checked: false,
    disabled: true,
  },
};

export const DisabledChecked:Story = {
  args: {
    checked: true,
    disabled: true,
  },
};
