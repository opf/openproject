import * as path from 'path';
import remarkGfm from 'remark-gfm';
import type { StorybookConfig } from '@storybook/angular';

const config:StorybookConfig = {
  stories: [
    "../src/**/*.mdx",
    "../src/**/*.stories.@(js|jsx|ts|tsx)",
  ],

  addons: [
    "@storybook/addon-links",
    "@storybook/addon-essentials",
    "@storybook/addon-interactions",
    {
      name: '@storybook/addon-docs',
      options: {
        mdxPluginOptions: {
          mdxCompileOptions: {
            remarkPlugins: [remarkGfm],
          },
        },
      },
    },
    "@storybook/preset-scss",
    "storybook-addon-designs",
    "./plugin-iframe/src/preset.js",
    '@storybook/addon-mdx-gfm',
  ],

  framework: {
    name: '@storybook/angular',
    options: {}
  },

  core: {
    disableTelemetry: true
  },

  features: {
  },

  staticDirs: [
    // Copy local static assets
    '../src/stories/assets/logo_openproject.png',
    '../src/stories/assets/logo_openproject_spot.png',
    // Copy font files to specific locations so the normal core SASS 
    // will load the files correctly without having to use variables
    '../src/assets/fonts/openproject_icon/openproject-icon-font.ttf',
    '../src/assets/fonts/openproject_icon/openproject-icon-font.svg',
    '../src/assets/fonts/openproject_icon/openproject-icon-font.eot',
    '../src/assets/fonts/openproject_icon/openproject-icon-font.woff',
    '../src/assets/fonts/openproject_icon/openproject-icon-font.woff2',
    '../src/assets/fonts/lato/Lato-Regular.woff',
    '../src/assets/fonts/lato/Lato-Regular.woff2',
    '../src/assets/fonts/lato/Lato-Bold.woff',
    '../src/assets/fonts/lato/Lato-Bold.woff2',
    '../src/assets/fonts/lato/Lato-Light.woff',
    '../src/assets/fonts/lato/Lato-Light.woff2',
    '../src/assets/fonts/lato/Lato-Italic.woff',
    '../src/assets/fonts/lato/Lato-Italic.woff2',
    '../src/assets/fonts/lato/Lato-BoldItalic.woff',
    '../src/assets/fonts/lato/Lato-BoldItalic.woff2',
    '../src/assets/fonts/lato/Lato-LightItalic.woff',
    '../src/assets/fonts/lato/Lato-LightItalic.woff2',
  ].map(from => ({
    from,
    to: path.join('/assets/frontend/', path.basename(from))
  })),

  docs: {
    autodocs: true
  }
};

export default config;
