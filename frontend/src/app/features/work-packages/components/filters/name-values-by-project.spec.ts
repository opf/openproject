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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { nameValuesByProject } from './name-values-by-project';

describe('nameValuesByProject', () => {
  const I18n = {
    t: (_key:string, { value, project }:{ value:string, project:string }) => `${value} (${project})`,
  } as unknown as I18nService;
  const scrum = { href: '/api/v3/projects/1', name: 'Scrum project' };
  const demo = { href: '/api/v3/projects/2', name: 'Demo project' };

  const value = (title:string, project?:{ href:string, name:string }) => ({
    $link: { title },
    name: title,
    project,
  }) as unknown as HalResource;

  it('names the projects of the values when they come from several projects', () => {
    const values = [value('Austin'), value('Cologne', scrum), value('Cologne', demo)];

    nameValuesByProject(values, I18n);

    expect(values.map((v) => v.name)).toEqual(['Austin', 'Cologne (Scrum project)', 'Cologne (Demo project)']);
  });

  it('keeps the names when the values come from a single project', () => {
    const values = [value('Austin'), value('Cologne', scrum), value('Rheinauhafen', scrum)];

    nameValuesByProject(values, I18n);

    expect(values.map((v) => v.name)).toEqual(['Austin', 'Cologne', 'Rheinauhafen']);
  });

  it('does not repeat the project when naming the values again', () => {
    const values = [value('Cologne', scrum), value('Cologne', demo)];

    nameValuesByProject(values, I18n);
    nameValuesByProject(values, I18n);

    expect(values.map((v) => v.name)).toEqual(['Cologne (Scrum project)', 'Cologne (Demo project)']);
  });
});
