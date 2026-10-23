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

import { createCodeBlockSpec as createBlockNoteCodeBlockSpec } from '@blocknote/core';
import { codeBlockOptions } from '@blocknote/code-block';

const { supportedLanguages } = codeBlockOptions;

function supportedLanguageId(language:string):string {
  const normalized = language.trim().toLowerCase();
  const match = Object.entries(supportedLanguages)
    .find(([id, { aliases }]) => id === normalized || aliases?.includes(normalized));

  return match?.[0] ?? 'text';
}

export function createCodeBlockSpec() {
  const spec = createBlockNoteCodeBlockSpec({ ...codeBlockOptions, defaultLanguage: 'text' });
  const { render } = spec.implementation;

  return {
    ...spec,
    implementation: {
      ...spec.implementation,
      render(this:ThisParameterType<typeof render>, ...[block, editor]:Parameters<typeof render>) {
        const language = supportedLanguageId(block.props.language);
        return render.call(this, { ...block, props: { ...block.props, language } }, editor);
      },
    },
  };
}
