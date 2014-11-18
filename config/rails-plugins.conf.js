require('shelljs/global');
var path = require('path'),
    _    = require('lodash');

function rubyBundler(subCmd) {
  var fullCmd = exec('bundle ' + subCmd, { silent: true });
  return fullCmd.code === 0 ? fullCmd.output : null;
}

var OpenProjectPlugins = {
  pluginPaths: _.memoize(function() {
    var allPaths = (rubyBundler('list --paths') || '').split('\n');
    return allPaths.filter(function(name) {
      // naive match
      return name.match(/openproject-/);
    });
  }),

  pluginNamesPaths: function() {
    return this.pluginPaths().reduce(function(obj, pluginPath) {
      var pluginName = path.basename(pluginPath).replace(/-[0-9a-fA-F]{12}$/, '');
      obj[pluginName] = pluginPath;
      return obj;
    }, {});
  },

  findPluginPath: _.memoize(function(name) {
    return this.pluginNamesPaths()[name];
  }, _.identity),

  pluginDirectories: function() {
    return this.pluginPaths().reduce(function(dirList, pluginPath) {
      var pluginDir = path.dirname(pluginPath);
      return dirList.indexOf(pluginDir) === -1 ? dirList.concat(pluginDir) : dirList;
    }, []);
  }
};

var TranslationsPlugin = {
  envPath: function() {
    if (env['OPENPROJECT_TRANSLATIONS_ROOT']) {
      return path.resolve(__dirname, '..', env['OPENPROJECT_TRANSLATIONS_ROOT']);
    }
  },

  findPluginPath: function() {
    return this.envPath() || OpenProjectPlugins.findPluginPath('openproject-translations') || '';
  },

  findLocaleFiles: function() {
    var localeFilePath = path.join(this.findPluginPath(), 'config', 'locales');
    return find(localeFilePath).filter(function(file) {
      return file.match(/js-([\w|-]){2,5}\.yml$/);
    });
  }
};

exports.pluginDirectories         = OpenProjectPlugins.pluginDirectories();
exports.translationsPluginLocales = TranslationsPlugin.findLocaleFiles();
exports.translationsPluginPath    = TranslationsPlugin.findPluginPath();
