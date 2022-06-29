// also exported from '@storybook/angular' if you can deal with breaking changes in 6.1
import { Story, Meta } from '@storybook/angular/types-6-0';
import Button from './button.component';

// More on default export: https://storybook.js.org/docs/angular/writing-stories/introduction#default-export
export default {
  title: 'Blocks/Button',
  component: Button,
} as Meta;

// More on component templates: https://storybook.js.org/docs/angular/writing-stories/introduction#using-args
const Template: Story<Button> = (args: Button) => ({
  props: args,
});

export const Default = Template.bind({});
// More on args: https://storybook.js.org/docs/angular/writing-stories/args
Default.args = {
  type: 'default',
  label: 'Default button style',
};

export const Main = Template.bind({});
// More on args: https://storybook.js.org/docs/angular/writing-stories/args
Main.args = {
  type: 'main',
  label: 'Primary action',
};

export const Accent = Template.bind({});
Accent.args = {
  type: 'accent',
  label: 'Secondary action',
};

export const Danger = Template.bind({});
Danger.args = {
  type: 'danger',
  label: 'Dangerous action',
};
