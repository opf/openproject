import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { OpSpotModule } from '../app/spot/spot.module';

const meta:Meta = {
  title: 'Components/List',
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const WithLinks:Story = {
  render: (args) => ({
    props: args,
    template: `
      <ul class="spot-list">
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">First link</a>
        </li>
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">Second link</a>
        </li>
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">Third link</a>
        </li>
      </ul>
   `,
  }),
};

export const WithCheckboxes:Story = {
  render: (args) => ({
    props: args,
    template: `
      <ul class="spot-list">
        <li class="spot-list--item">
          <label class="spot-list--item-action">
            <spot-checkbox [tabindex]="-1"></spot-checkbox>
            <div class="spot-list--item-title">
              First checky
            </div>
          </label>
        </li>
        <li class="spot-list--item">
          <label class="spot-list--item-action">
            <spot-checkbox [tabindex]="-1"></spot-checkbox>
            <div class="spot-list--item-title">
              Second checky
            </div>
          </label>
        </li>
        <li class="spot-list--item">
          <label class="spot-list--item-action">
            <spot-checkbox [tabindex]="-1"></spot-checkbox>
            <div class="spot-list--item-title">
              Third checky
            </div>
          </label>
        </li>
      </ul>
   `,
  }),
};

export const Compact:Story = {
  render: (args) => ({
    props: args,
    template: `
      <ul class="spot-list spot-list_compact">
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">First link</a>
        </li>
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">Second link</a>
        </li>
        <li class="spot-list--item">
          <a href="#" class="spot-list--item-action">Third link</a>
        </li>
      </ul>
   `,
  }),
};
