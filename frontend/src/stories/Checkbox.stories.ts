import { moduleMetadata } from '@storybook/angular';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';

import { OpSpotModule } from '../app/spot/spot.module';
import { SpotCheckboxComponent } from '../app/spot/components/checkbox/checkbox.component';

export default {
  title: 'Components/Checkbox',
  component: SpotCheckboxComponent,
  decorators: [
    withKnobs,
    moduleMetadata({
      imports: [
        OpSpotModule,
      ],
    }),
  ],
};

const angularTemplate = require('!!raw-loader!./CheckboxAngular.stories.html').default as string; // eslint-disable-line

export const Angular = () => {
  return {
    title: 'Angular',
    template: angularTemplate,
    props: {
      name: text('name', ''),
      checked: boolean('checked', false),
      disabled: boolean('disabled', false),
      selectedChange: action('change'),
    },
  };
};

const htmlTemplate = require('!!raw-loader!./CheckboxHTML.stories.html').default as string; // eslint-disable-line

export const HTML = () => ({
  title: 'HTML',
  template: htmlTemplate,
});
