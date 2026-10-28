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

import type { Meta, StoryObj } from '@storybook/html-vite';

interface ExpandableTextArgs {
  text:string;
  width:number;
  truncate:'single_line'|'multi_line';
  lines:number;
  expansion:'inline'|'dialog';
}

const meta:Meta<ExpandableTextArgs> = {
  title: 'OpenProject/ExpandableText',
  parameters: {
    viewComponent: { preview: 'op_primer/expandable_text_component', example: 'playground' },
  },
  argTypes: {
    width: { control: { type: 'range', min: 100, max: 600, step: 10 } },
    truncate: { control: 'inline-radio', options: ['single_line', 'multi_line'] },
    lines: { control: { type: 'range', min: 2, max: 12, step: 1 } },
    expansion: { control: 'inline-radio', options: ['inline', 'dialog'] },
  },
  args: {
    text: 'OpenProject is an open source project management software that supports '
      + 'classic, agile, and hybrid approaches.',
    width: 200,
    truncate: 'single_line',
    lines: 3,
    expansion: 'inline',
  },
};

export default meta;

type Story = StoryObj<ExpandableTextArgs>;

export const SingleLine:Story = {};

export const MultiLineDialog:Story = {
  args: { truncate: 'multi_line', expansion: 'dialog', width: 300 },
};
