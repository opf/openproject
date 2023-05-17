import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { OpSpotModule } from '../app/spot/spot.module';

import { BreadcrumbsContent } from '../app/spot/components/breadcrumbs/breadcrumbs-content';
import { SpotBreadcrumbsComponent } from '../app/spot/components/breadcrumbs/breadcrumbs.component';

const meta:Meta = {
  title: 'Patterns/Breadcrumbs',
  component: SpotBreadcrumbsComponent,
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
    props: {
      ...args,
      content: new BreadcrumbsContent([
        { icon: 'folder', text: 'OpenProject storage' },
        { text: 'Public' },
        { text: 'Shared' },
      ]),
    },
  }),
};

export const FourLevels:Story = {
  render: (args) => ({
    props: {
      ...args,
      content: new BreadcrumbsContent([
        { icon: 'folder', text: 'Root' },
        { text: 'Second level' },
        { text: 'Third level' },
        { text: 'Current level' },
      ]),
    },
  }),
};

export const FiveLevels:Story = {
  render: (args) => ({
    props: {
      ...args,
      content: new BreadcrumbsContent([
        { icon: 'folder', text: 'Root folder with a long name' },
        { text: 'Second level' },
        { text: 'Third level with an even longer name' },
        { text: 'Fourth level with the longest name from all' },
        { text: 'Current level and even this one has a long name' },
      ]),
    },
  }),
};
