/**
 * @license Copyright (c) 2003-2017, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md.
 */

/**
 * @module block-quote/blockquote
 */

import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import buildModelConverter from '@ckeditor/ckeditor5-engine/src/conversion/buildmodelconverter';
import buildViewConverter from '@ckeditor/ckeditor5-engine/src/conversion/buildviewconverter';

export default class OpTableWidget extends Plugin {
	static get pluginName() {
		return 'OP-Table';
	}

	init() {
    const editor = this.editor;
    const data = editor.data;
    const schema = editor.document.schema;
    const editing = editor.editing;

		schema.registerItem( 'table' );
    schema.allow( { name: 'table', inside: '$root' } );
    // thead
    schema.allow( { name: 'thead', inside: 'table' } );
    schema.allow( { name: 'tr', inside: 'thead' } );
    schema.allow( { name: 'th', inside: 'tr' } );

    // tbody
		schema.allow( { name: 'tbody', inside: 'table' } );
    schema.allow( { name: 'tr', inside: 'tbody' } );
    schema.allow( { name: 'td', inside: 'tr' } );
    // schema.allow( { name: '$block', inside: 'opTable' } );


		buildModelConverter().for( data.modelToView, editing.modelToView )
      .fromElement( 'opTable' )
      .toElement('div')

    // Build converter from view to model for data pipeline.
    buildViewConverter().for( data.viewToModel )
      .fromElement( 'div' )
      .fromAttribute( 'class', 'op-ckeditor-widget--table')
      .toElement('opTable');
	}
}
