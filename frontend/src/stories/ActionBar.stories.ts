import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import { OpSpotModule } from '../app/spot/spot.module';

const meta:Meta = {
  title: 'Patterns/ActionBar',
  decorators: [
    moduleMetadata({
      imports: [OpSpotModule],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const InModal:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-modal" style="border: rgb(224, 224, 224) 1px solid">
        <div class="spot-modal--header">Delete attachment</div>
        <div class="spot-modal--body spot-container">
          <span class="spot-body-small">Are you sure you want to delete this file? This action is not reversible.</span>
        </div>
        <div class="spot-action-bar">
          <div class="spot-action-bar--right">
            <button
              type="button"
              class="spot-action-bar--action button"
            >Cancel</button>
            <button
              type="button"
              class="spot-action-bar--action button -danger"
            >
              <span class="spot-icon spot-icon_delete"></span>
              <span>Delete attachment</span>
            </button>
          </div>
        </div>
      </div>
   `,
  }),
};

export const Default:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-action-bar">
        <div class="spot-action-bar--left">
          <spot-selector-field
            class="spot-action-bar--action"
            label="Remember this choice"
          >
            <spot-checkbox slot="input"></spot-checkbox>
          </spot-selector-field>
        </div>
        <div class="spot-action-bar--right">
          <button
            type="button"
            class="spot-action-bar--action button -highlight"
          >Okay
          </button>
        </div>
      </div>
   `,
  }),
};

export const LeftButtons:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-action-bar">
        <div class="spot-action-bar--left">
          <button
            type="button"
            class="spot-action-bar--action button"
          >Cancel</button>
          <button
            type="button"
            class="spot-action-bar--action button -highlight"
          >Save</button>
        </div>
        <div class="spot-action-bar--right">
          <spot-selector-field
            class="spot-action-bar--action"
            [label]="'Remember this choice'"
          >
            <spot-checkbox slot="input"></spot-checkbox>
          </spot-selector-field>
        </div>
      </div>
   `,
  }),
};

export const Transparent:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-action-bar spot-action-bar_transparent">
        <div class="spot-action-bar--left">
          <spot-selector-field
            class="spot-action-bar--action"
            [label]="'Remember this choice'"
          >
            <spot-checkbox slot="input"></spot-checkbox>
          </spot-selector-field>
        </div>
        <div class="spot-action-bar--right">
          <button
            type="button"
            class="spot-action-bar--action button"
          >
            <span>Cancel</span>
          </button>
          <button
            type="button"
            class="spot-action-bar--action button -danger"
          >
            <span class="spot-icon spot-icon_delete"></span>
            <span>Delete</span>
          </button>
        </div>
      </div>
   `,
  }),
};

export const NoSideOption:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-action-bar">
        <div class="spot-action-bar--right">
          <button
            type="button"
            class="spot-action-bar--action button"
          >
            <span>Cancel</span>
          </button>
          <button
            type="button"
            class="spot-action-bar--action button -highlight"
          >
            <span>Next</span>
          </button>
        </div>
      </div>
   `,
  }),
};

export const MoreButtons:Story = {
  render: (args) => ({
    props: args,
    template: `
      <div class="spot-action-bar">
        <div class="spot-action-bar--left">
          <button
            type="button"
            class="spot-action-bar--action button"
          >
            <span class="spot-icon spot-icon_watched"></span>
            <span>Watch</span>
          </button>
          <button
            type="button"
            class="spot-action-bar--action button"
          >
            <span class="spot-icon spot-icon_mark-read"></span>
            <span>Mark as read</span>
          </button>
          <button
            type="button"
            class="spot-action-bar--action button"
          >
            <span>More</span>
            <span class="spot-icon spot-icon_dropdown"></span>
          </button>
        </div>
      </div>
   `,
  }),
};
