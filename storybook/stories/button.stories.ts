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

interface ButtonArgs {
  scheme:'default'|'primary'|'danger'|'invisible'|'link';
  size:'small'|'medium'|'large';
  block:boolean;
  disabled:boolean;
  inactive:boolean;
  align_content:'center'|'start';
  tag:'button'|'a';
  label_wrap:boolean;
}

const meta:Meta<ButtonArgs> = {
  title: 'Primer/Button',
  parameters: {
    viewComponent: { preview: 'primer/beta/button', example: 'playground' },
    design: {
      type: 'figma',
      url: 'https://www.figma.com/design/NVKjUO6QNDqa6bZT0oiGr0/SE-657?node-id=90-2',
    },
  },
  argTypes: {
    scheme: { control: 'select', options: ['default', 'primary', 'danger', 'invisible', 'link'] },
    size: { control: 'inline-radio', options: ['small', 'medium', 'large'] },
    align_content: { control: 'inline-radio', options: ['center', 'start'] },
    tag: { control: 'inline-radio', options: ['button', 'a'] },
  },
  args: {
    scheme: 'default',
    size: 'medium',
    block: false,
    disabled: false,
    inactive: false,
    align_content: 'center',
    tag: 'button',
    label_wrap: false,
  },
};

export default meta;

type Story = StoryObj<ButtonArgs>;

export const Playground:Story = {};

export const Primary:Story = {
  args: { scheme: 'primary' },
};

export const Danger:Story = {
  args: { scheme: 'danger' },
};
