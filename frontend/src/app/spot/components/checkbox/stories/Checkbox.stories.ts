import { moduleMetadata, Meta, Story } from '@storybook/angular';

import { OpSpotModule } from '../../../spot.module';
import { SpotCheckboxComponent } from '../checkbox.component';

export default {
  title: 'Blocks/Checkbox',
  component: SpotCheckboxComponent,
  decorators: [
    moduleMetadata({
      imports: [
        OpSpotModule,
      ],
    }),
  ],
  parameters: {
    design: {
      type: 'figma',
      url: 'https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=1785%3A6910',
    },
  },
} as Meta;

const Angular:Story = (args) => ({
  props: {
    checked: true,
    disabled: false,
    ...args,
  },
});

export const AngularStory = Angular.bind({});
AngularStory.parameters = { component: SpotCheckboxComponent };
AngularStory.storyName = 'Angular component';

const htmlTemplate = require('!!raw-loader!./CheckboxHTML.html').default as string; // eslint-disable-line

export const HTML = () => ({
  template: htmlTemplate,
});
HTML.storyName = 'HTML template';
