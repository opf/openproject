import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';
import { SpotToggleComponent } from '../toggle.component';

const meta:Meta = {
  title: 'Components/Toggle',
  component: SpotToggleComponent,
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
    name: 'my-toggle',
    value: null,
    options: [
      { value: 'first', title: 'Unread' },
      { value: 'second', title: 'All' },
    ],
  },
};

export const WithValue:Story = {
  args: {
    value: 'first',
    options: [
      { value: 'first', title: 'Unread' },
      { value: 'second', title: 'All' },
    ],
  },
};

export const FourOptions:Story = {
  args: {
    name: 'my-toggle',
    value: 'first',
    options: [
      { value: 'first', title: 'First option' },
      { value: 'second', title: 'Second option' },
      { value: 'third', title: 'Third option' },
      { value: 'best', title: 'Best option' },
    ],
  },
};
