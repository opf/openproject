module.exports = async ({ config, mode }) => {
  config.resolve = config.resolve || {};
  config.resolve.alias['core-js/modules/es.promise.js$'] = false;
  return config;
};
