import { setCompodocJson } from "@storybook/addon-docs/angular";
import { themes } from '@storybook/theming';
import docJson from "../documentation.json";

setCompodocJson(docJson);

export const parameters = {
  parameters: {
    viewMode: 'docs',
  },
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
  docs: {
    inlineStories: true,
    theme: themes.light,
  },
  options: {
    storySort: {
      method: 'alphabetical',
      order: [
        'OpenProject Angular SPOT components',
        'Blocks',
        // TODO: Add manual sort order for components and patterns 
      ],
    },
  },
}
