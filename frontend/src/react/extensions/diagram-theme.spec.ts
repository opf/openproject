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

import { initializeMermaid } from '@blocknote/diagram-block';
import mermaid from 'mermaid';
import { applyDiagramTheme } from './diagram-theme';

describe('applyDiagramTheme', () => {
  it('renders diagrams with the dark Mermaid theme in dark mode', () => {
    applyDiagramTheme('dark');

    expect(mermaid.mermaidAPI.getConfig().theme).toBe('dark');
  });

  it('renders diagrams with the default Mermaid theme in light mode', () => {
    applyDiagramTheme('light');

    expect(mermaid.mermaidAPI.getConfig().theme).toBe('default');
  });

  it('keeps the theme and the rendering options of the diagram block when the block initializes Mermaid', () => {
    applyDiagramTheme('dark');
    initializeMermaid();

    expect(mermaid.mermaidAPI.getConfig()).toEqual(expect.objectContaining({ theme: 'dark', htmlLabels: false }));
  });
});
