#!/usr/bin/env node

const webfontsGenerator = require('webfonts-generator');
const path = require('path');
const glob = require("glob")

const TEMPLATE_DIR = path.resolve(process.argv[2]);
const CSS_FONT_URL = "../../../../../frontend/src/assets/fonts/openproject_icon/";
const FONT_DESTINATION = path.resolve(__dirname, '..', '..', '..', '..', '..', 'frontend', 'src', 'assets', 'fonts', 'openproject_icon');

const files = glob.sync(path.join(TEMPLATE_DIR, 'src/*.svg'));
const filesBoxed = glob.sync(path.join(TEMPLATE_DIR, 'icons/*.svg'));

webfontsGenerator({
  files: filesBoxed,
  "fontName": "openproject-spot-icon-font",
  "cssFontsUrl": "../../../../../frontend/src/assets/fonts/openproject_spot_icon/",
  "dest": path.resolve(__dirname, '..', '..', '..', '..', '..', 'frontend', 'src', 'assets', 'fonts', 'openproject_spot_icon'),
  "cssDest": path.join(
    path.resolve(__dirname, '..', 'styles', 'sass', 'common'),
    'icon.sass',
  ),
  "cssTemplate": path.join(TEMPLATE_DIR, "icon.template.sass"),
  "types": ['woff2', 'woff'],
}, function(error) {
  if (error) {
    console.log('Failed to build icon font. ', error);
  }
});

webfontsGenerator({
  files,
  "fontName": "openproject-icon-font",
  "cssFontsUrl": CSS_FONT_URL,
  "dest": FONT_DESTINATION,
  "cssDest": path.join(
    path.resolve(__dirname, '..', '..', '..', '..', '..', 'frontend', 'src', 'global_styles', 'fonts'),
    '_openproject_icon_definitions.sass',
  ),
  "cssTemplate": path.join(TEMPLATE_DIR, "openproject-icon-font.template.sass"),
  "classPrefix": "icon-",
  "baseSelector": ".icon",
  "html": true,
  "htmlDest": path.join(
    path.resolve(__dirname, '..', '..', '..', '..', '..', 'frontend', 'src', 'global_styles', 'fonts'),
    '_openproject_icon_font.lsg',
  ),
  "htmlTemplate": path.join(TEMPLATE_DIR, "openproject-icon-font.template.lsg"),
  "types": ['woff2', 'woff'],
  "fixedWidth": true,
  "descent": 100
}, function(error) {
  if (error) {
    console.log('Failed to build icon font. ', error);
  }
});
