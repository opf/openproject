import { Application } from '@hotwired/stimulus';
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers';

const stimulus = Application.start(document.documentElement);
// eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-member-access
(window as any).Stimulus = stimulus;
const context = require.context('./controllers', true, /\.ts$/);
stimulus.load(definitionsFromContext(context));
