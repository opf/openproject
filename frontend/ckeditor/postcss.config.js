'use strict';

const path = require( 'path' );
const postcssImport = require( 'postcss-import' );
const postcssCssnext = require( 'postcss-cssnext' );
//const CKThemeImporter = require( './ck-theme-importer' );

module.exports = {
  plugins: [
    postcssImport(),
    postcssCssnext()
  ]
};
