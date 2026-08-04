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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

export const onboardingTourStorageKey = 'openProject-onboardingTour';
export type OnboardingTourNames = 'homescreen'|'workPackages'|'workPackagesFullView'|'gantt'|'final'|'boards'|'teamPlanner';

function matchingFilter(list:NodeListOf<HTMLElement>, filterFunction:(match:HTMLElement) => boolean):HTMLElement|null {
  for (let i = 0; i < list.length; i++) {
    if (filterFunction(list[i])) {
      return list[i];
    }
  }

  return null;
}

export function waitForElement(
  selector:string,
  containerSelector:string,
  execFunction:(match:HTMLElement) => void,
  filterFunction:(match:HTMLElement) => boolean = () => true,
):void {
  const container = document.querySelector(containerSelector)!;
  // If the element is ready immediately
  const initial = matchingFilter(container.querySelectorAll<HTMLElement>(selector), filterFunction);
  if (initial) {
    execFunction(initial);
    return;
  }

  // Wait for the element to be ready
  const observer = new MutationObserver((mutations, observerInstance) => {
    const matches = matchingFilter(container.querySelectorAll<HTMLElement>(selector), filterFunction);
    if (matches) {
      execFunction(matches);
      observerInstance.disconnect();
    }
  });

  observer.observe(container, {
    childList: true,
    subtree: true,
  });
}
