#!/usr/bin/env node

const webfontsGenerator = require('webfonts-generator');
const path = require('path');
const fs = require('fs');
const glob = require("glob")

webfontsGenerator({
  files: glob.sync("src/*.svg"),
  "fontName": "openproject-icon-font",
  "cssFontsUrl": "../assets/openproject_icon/",
  "cssDest": path.join(path.resolve(__dirname, '..', '..', 'stylesheets', 'fonts'), '_openproject_icon_definitions.scss'),
  "cssTemplate": "openproject-icon-font.template.scss",
  "classPrefix": "icon-",
  "baseSelector": ".icon",
  "html": true,
  "htmlDest": path.join(path.resolve(__dirname, '..', '..', 'stylesheets', 'fonts'), '_openproject_icon_font.lsg'),
  "htmlTemplate": "openproject-icon-font.template.lsg",
  "types": ['woff2', 'woff'],
  "fixedWidth": true,
  "descent": 100,
  dest: ''
}, function(error) {
  if (error) {
    console.log('Failed to build icon font. ', error);
  }
});
