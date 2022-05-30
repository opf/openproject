import { Application, defaultSchema } from '@hotwired/stimulus';
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers';

const customSchema = {
  ...defaultSchema,
  controllerAttribute: 'op-controller',
  actionAttribute: 'op-action',
  targetAttribute: 'op-target',
  targetAttributeForScope: (identifier:string) => `op-${identifier}-target`,
};

const stimulus = Application.start(document.documentElement, customSchema);
// eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-member-access
(window as any).Stimulus = stimulus;
const context = require.context('./controllers', true, /\.ts$/);
stimulus.load(definitionsFromContext(context));
