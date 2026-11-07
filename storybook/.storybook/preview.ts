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

import type { Preview } from '@storybook/html-vite';

interface ViewComponentParameters {
  preview:string;
  example:string;
}

async function fetchHtml(url:string) {
  const response = await fetch(url);
  const html = await response.text();
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText} for ${url}\n\n${html}`);
  }
  return html;
}

async function loadFrontendAssets() {
  const html = await fetchHtml('/storybook/assets');
  document.head.append(document.createRange().createContextualFragment(html));
}

const preview:Preview = {
  async beforeAll() {
    Object.assign(document.body.dataset, {
      controller: 'application',
      colorMode: 'auto',
      lightTheme: 'light',
      darkTheme: 'dark',
    });
    await loadFrontendAssets();
  },
  loaders: [
    async ({ args, parameters }) => {
      const { preview, example } = parameters.viewComponent as ViewComponentParameters;
      const query = new URLSearchParams(Object.entries(args).map(([name, value]) => [name, String(value)]));
      return { html: await fetchHtml(`/storybook/previews/${preview}/${example}?${query.toString()}`) };
    },
  ],
  render: (_args, { loaded }) => loaded.html as string,
};

export default preview;
