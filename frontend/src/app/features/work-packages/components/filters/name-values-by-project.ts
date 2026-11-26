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

export function nameValuesByProject(values:HalResource[], I18n:I18nService):void {
  const projectHrefs = new Set(values.map((value) => projectOf(value)?.href).filter(Boolean));
  if (projectHrefs.size < 2) return;

  values.forEach((value) => {
    const project = projectOf(value);
    if (!project) return;

    value.name = I18n.t('js.filter.value_with_project', { value: value.$link.title, project: project.name });
  });
}

function projectOf(value:HalResource):HalResource|undefined {
  return value.project as HalResource|undefined;
}
