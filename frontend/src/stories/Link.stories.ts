import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { OpSpotModule } from '../app/spot/spot.module';

const meta:Meta = {
  title: 'Components/Link',
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
      <a
        href="#"
        class="spot-link"
      >This is a spot-link</a>
   `,
  }),
};

export const LeftIcon:Story = {
  render: (args) => ({
    props: args,
    template: `
      <a
        href="#"
        class="spot-link"
      >
        <span>This is a spot-link</span>
        <span class="spot-icon spot-icon_add"></span>
      </a>
   `,
  }),
};

export const RightIcon:Story = {
  render: (args) => ({
    props: args,
    template: `
      <a
        href="#"
        class="spot-link"
      >
        <span class="spot-icon spot-icon_add"></span>
        <span>This is a spot-link</span>
      </a>
   `,
  }),
};

export const BothIcons:Story = {
  render: (args) => ({
    props: args,
    template: `
      <a
        href="#"
        class="spot-link"
      >
        <span class="spot-icon spot-icon_add"></span>
        <span>This is a spot-link</span>
        <span class="spot-icon spot-icon_add"></span>
      </a>
   `,
  }),
};
