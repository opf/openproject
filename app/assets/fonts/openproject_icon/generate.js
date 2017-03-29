#!/usr/bin/env node

const webfontsGenerator = require('webfonts-generator');
const fs = require('fs');
const glob = require("glob")

webfontsGenerator({
  files: glob.sync("src/*.svg"),
  "fontName": "openproject-icon-font",
  "cssFontsUrl": "../assets/openproject_icon/",
  "classPrefix": "icon-",
  "baseSelector": ".icon",
  "types": ['woff2', 'woff'],
  "fixedWidth": true,
  dest: ''
}, function(error) {
  if (error) {
    console.log('Failed to build icon font. ', error);
  } else {
    fs.rename('openproject-icon-font.css', '../../stylesheets/fonts/_openproject_icon_definitions.scss');
    console.log('Done!');
  }
});
