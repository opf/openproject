import { Meta } from '@storybook/angular';

export default {
  title: "Example Stories/Action Bar",
} as Meta;

const htmlTemplate = require('!!raw-loader!./ActionBar.example.html').default as string; // eslint-disable-line

export const HTML = () => ({
  title: 'HTML',
  template: htmlTemplate,
});
