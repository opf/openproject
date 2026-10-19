//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { BlockNoteEditor, BlockNoteSchema, PartialBlock } from '@blocknote/core';
import { createCodeBlockSpec } from './code-block';

const schema = BlockNoteSchema.create().extend({ blockSpecs: { codeBlock: createCodeBlockSpec() } });

function mountCodeBlock(props:{ language?:string }) {
  const element = document.createElement('div');
  document.body.appendChild(element);
  const initialContent = [{ type: 'codeBlock', props, content: 'puts 1' }] as PartialBlock<typeof schema.blockSchema>[];
  const editor = BlockNoteEditor.create({ schema, initialContent });
  editor.mount(element);

  return { editor, select: element.querySelector<HTMLSelectElement>('[data-content-type="codeBlock"] select')! };
}

describe('createCodeBlockSpec', () => {
  it('offers the supported languages', () => {
    const { select } = mountCodeBlock({ language: 'ruby' });

    expect(select.value).toBe('ruby');
  });

  it('shows a language stored under an alias as its supported language', () => {
    const { editor, select } = mountCodeBlock({ language: 'js' });

    expect(select.value).toBe('javascript');
    expect(editor.document[0].props).toEqual(expect.objectContaining({ language: 'js' }));
  });

  it('shows a language it does not support as plain text, keeping the stored one', () => {
    const { editor, select } = mountCodeBlock({ language: 'go' });

    expect(select.value).toBe('text');
    expect(editor.document[0].props).toEqual(expect.objectContaining({ language: 'go' }));
  });

  it('starts new code blocks as plain text', () => {
    const { select } = mountCodeBlock({});

    expect(select.value).toBe('text');
  });
});
