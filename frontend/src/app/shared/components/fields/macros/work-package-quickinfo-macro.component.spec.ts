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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageQuickinfoMacroComponent } from 'core-app/shared/components/fields/macros/work-package-quickinfo-macro.component';

describe('WorkPackageQuickinfoMacroComponent', () => {
  const component = Object.create(
    WorkPackageQuickinfoMacroComponent.prototype,
  ) as WorkPackageQuickinfoMacroComponent;

  it('identifies closed work packages', () => {
    const workPackage = { status: { isClosed: true } } as unknown as WorkPackageResource;

    expect(component.isClosed(workPackage)).toBe(true);
  });

  it('does not mark open work packages as closed', () => {
    const workPackage = { status: { isClosed: false } } as unknown as WorkPackageResource;

    expect(component.isClosed(workPackage)).toBe(false);
  });
});
