require('shelljs/global');
var path = require('path');

function rubyBundler(subCmd) {
  var fullCmd = exec('bundle ' + subCmd);
  return fullCmd.code === 0 ? fullCmd.output : null;
}

var TranslationsPlugin = {
  envPath: function() {
    if (env['OPENPROJECT_TRANSLATIONS_ROOT']) {
      return path.resolve(__dirname, '..', env['OPENPROJECT_TRANSLATIONS_ROOT']);
    }
  },

  findBundlerPath: function() {
    return rubyBundler('show openproject-translations');
  },

  findPluginPath: function() {
    return this.envPath() || this.findBundlerPath() || '';
  },

  findLocaleFiles: function() {
    var localeFilePath = path.join(this.findPluginPath(), 'config', 'locales');
    return find(localeFilePath).filter(function(file) {
      return file.match(/js-([\w|-]){2,5}\.yml$/);
    });
  }
};

exports.translationsPluginLocales = TranslationsPlugin.findLocaleFiles();
exports.translationsPluginPath    = TranslationsPlugin.findPluginPath();
