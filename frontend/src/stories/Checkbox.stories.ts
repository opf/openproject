import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../app/spot/spot.module';
import { SpotCheckboxComponent } from '../app/spot/components/checkbox/checkbox.component';

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
      url: 'https://www.figma.com/file/XhCsrvs6rePifqbBpKYRWD/Components-Library?node-id=855%3A6406',
    },
  },
  args: {
    checked: true,
    disabled: false,
  },
};

export const Angular = () => {
  return {
    title: 'Angular',
    component: SpotCheckboxComponent,
  };
};

const htmlTemplate = require('!!raw-loader!./CheckboxHTML.stories.html').default as string; // eslint-disable-line

export const HTML = () => ({
  title: 'HTML',
  template: htmlTemplate,
});
