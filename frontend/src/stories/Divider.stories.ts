import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { OpSpotModule } from '../app/spot/spot.module';

const meta:Meta = {
  title: 'Components/Divider',
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Soft:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-container">
        <h1 class="spot-subheader-small">Some header with a soft divider below</h1>
        <div class="spot-divider"></div>
        <p class="spot-body-big">
          Lorem ipsum goes here but I'm too lazy to copy paste it from somewhere so I'll just ramble on
          until I think it has been enough. That was a very long sentence so I'll do one shorter one. Blablabla is what I say.
        </p>
      </div>
   `,
  }),
};

export const Strong:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-container">
        <h1 class="spot-subheader-small">Strong divider below</h1>
        <div class="spot-divider spot-divider_strong"></div>
        <p class="spot-body-big">
          Lorem ipsum goes here but I'm too lazy to copy paste it from somewhere so I'll just ramble on
          until I think it has been enough. That was a very long sentence so I'll do one shorter one. Blablabla is what I say.
        </p>
      </div>
   `,
  }),
};
