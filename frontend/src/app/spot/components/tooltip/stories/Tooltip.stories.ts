import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';
import { SpotTooltipComponent } from '../tooltip.component';

const meta:Meta = {
  title: 'Components/Tooltip',
  component: SpotTooltipComponent,
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Default:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-tooltip>
        <span slot="trigger">
          Hover me to see the tooltip. By default, tooltips take a maximum of 80% of their parents' width
        </span>
        <p
          slot="body"
          class="spot-body-small"
        >
          This is an example tooltip.
        </p>
      </spot-tooltip>
   `,
  }),
};

export const InList:Story = {
  render: (args) => ({
    props: args,
    template: `
      <ul class="spot-list">
        <li class="spot-list--item">
          <spot-tooltip alignment="bottom-center">
            <ng-container slot="trigger">
              <label class="spot-list--item-action">
                <spot-checkbox></spot-checkbox>
                <div class="spot-list--item-title spot-list--item-title_ellipse-text">Checky with a tooltip</div>
              </label>
            </ng-container>

            <p
              slot="body"
              class="spot-body-small"
            >
              This is a great checkbox.
            </p>
          </spot-tooltip>
        </li>
        <li class="spot-list--item">
          <spot-tooltip
            alignment="bottom-center"
            disabled="true"
          >
            <ng-container slot="trigger">
              <label class="spot-list--item-action">
                <spot-checkbox></spot-checkbox>
                <div class="spot-list--item-title spot-list--item-title_ellipse-text">Checky with a disabled tooltip</div>
              </label>
            </ng-container>

            <p
              slot="body"
              class="spot-body-small"
            >
              This tooltip is not going to show.
            </p>
          </spot-tooltip>
        </li>
        <li class="spot-list--item">
          <label class="spot-list--item-action">
            <spot-checkbox></spot-checkbox>
            <div class="spot-list--item-title spot-list--item-title_ellipse-text">Checky without a tooltip</div>
          </label>
        </li>
      </ul>
   `,
  }),
};

export const Dark:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-tooltip dark="true">
        <span slot="trigger">Hover me to see the tooltip.</span>
        <p
          slot="body"
          class="spot-body-small"
        >
          This is a dark tooltip.
        </p>
      </spot-tooltip>
   `,
  }),
};

export const Multiline:Story = {
  render: (args) => ({
    props: args,
    template: `
      <spot-tooltip>
        <span slot="trigger">Hover me to see the tooltip.</span>
        <p
          slot="body"
          class="spot-body-small"
        >
          This is a tooltip with a very long text <br />
          that has a break in the middle so that we <br />
          can get some multiline action.
        </p>
      </spot-tooltip>
   `,
  }),
};
