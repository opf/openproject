const path = require('path');

module.exports = {
  stories: [
    "../src/**/*.stories.mdx",
    "../src/**/*.stories.@(js|jsx|ts|tsx)"
  ],
  addons: [
    "@storybook/addon-links",
    "@storybook/addon-essentials",
    "@storybook/addon-interactions",
    "@storybook/addon-docs",
    "@storybook/preset-scss",
    "storybook-addon-designs",
    "./plugin-iframe/src/preset.js"
  ],
  framework: "@storybook/angular",
  core: {
    builder: "@storybook/builder-webpack5",
    disableTelemetry: true,
  },
  features: {
    previewMdx2: true,
    // modernInlineRender: true,
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
  ].map((from) => ({
    from, to: path.join('/assets/frontend/', path.basename(from)),
  })),
};
