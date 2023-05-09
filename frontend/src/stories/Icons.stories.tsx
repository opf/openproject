import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { OpSpotModule } from '../app/spot/spot.module';

const meta:Meta = {
  title: 'Components/Icons',
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
      <span class="spot-icon spot-icon_add"></span>
      <span class="spot-icon spot-icon_accountable"></span>
      <span class="spot-icon spot-icon_add-link"></span>
      <span class="spot-icon spot-icon_contacts"></span>
      <span class="spot-icon spot-icon_edit"></span>
   `,
  }),
};

export const Button:Story = {
  render: (args) => ({
    props: args,
    template: `
      <button class="button">
        Add work package
        <span class="spot-icon spot-icon_add"></span>
      </button>
   `,
  }),
};

export const Link:Story = {
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

