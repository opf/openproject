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
    { from: '../src/stories/assets', to: '/assets' },
  ],
};
