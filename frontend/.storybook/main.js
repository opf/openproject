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
    { from: '../src/stories/assets/', to: '/assets' },
    
    // Copy font files to specific locations so the normal core SASS 
    // will load the files correctly without having to use variables
    { from: '../src/assets/fonts/openproject_icon/', to: '/assets/frontend/' },
    { from: '../src/assets/fonts/lato/', to: '/assets/frontend/' },
  ],
};
