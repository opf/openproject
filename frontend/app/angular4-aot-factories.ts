// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

// AOT does not allow anoynmous or lambda functions to upgrade
// ng1 services.
// Thus, we have to export EACH factory on its own...
//
// https://github.com/rangle/angular-2-aot-sandbox#func-in-providers-usefactory-top

export function upgradeFactoryHalResource(i:any) { return i.get('HalResource'); }
export function upgradeFactoryQueryResource(i:any) { return i.get('QueryResource'); }
export function upgradeFactoryQueryFilterInstanceResource(i:any) { return i.get('QueryFilterInstanceResource'); }
export function upgradeFactory$rootScope(i:any) { return i.get('$rootScope'); }
export function upgradeFactoryI18n(i:any) { return i.get('I18n'); }
export function upgradeFactory$state(i:any) { return i.get('$state'); }
export function upgradeFactory$q(i:any) { return i.get('$q'); }
export function upgradeFactory$timeout(i:any) { return i.get('$timeout'); }
export function upgradeFactory$locale(i:any) { return i.get('$locale'); }
export function upgradeFactoryNotificationsService(i:any) { return i.get('NotificationsService'); }
export function upgradeFactorycolumnsModal(i:any) { return i.get('columnsModal'); }
export function upgradeFactoryFocusHelper(i:any) { return i.get('FocusHelper'); }
export function upgradeFactoryhalRequest(i:any) { return i.get('halRequest'); }
export function upgradeFactorywpMoreMenuService(i:any) { return i.get('wpMoreMenuService'); }
export function upgradeFactoryTimezoneService(i:any) { return i.get('TimezoneService'); }
export function upgradeFactoryv3Path(i:any) { return i.get('v3Path'); }
export function upgradeFactorywpDestroyModal(i:any) { return i.get('wpDestroyModal'); }
export function upgradeFactorysortingModal(i:any) { return i.get('sortingModal'); }
export function upgradeFactorygroupingModal(i:any) { return i.get('groupingModal'); }
export function upgradeFactoryshareModal(i:any) { return i.get('shareModal'); }
export function upgradeFactorysaveModal(i:any) { return i.get('saveModal'); }
export function upgradeFactorysettingsModal(i:any) { return i.get('settingsModal'); }
export function upgradeFactoryexportModal(i:any) { return i.get('exportModal'); }
export function upgradeFactorytimelinesModal(i:any) { return i.get('timelinesModal'); }
export function upgradeFactorywpRelations(i:any) { return i.get('wpRelations'); }
export function upgradeFactorystates(i:any) { return i.get('states'); }
export function upgradeFactorypaginationService(i:any) { return i.get('paginationService'); }
export function upgradeFactorykeepTab(i:any) { return i.get('keepTab'); }
export function upgradeFactorytemplateRenderer(i:any) { return i.get('templateRenderer'); }
export function upgradeFactorywpDisplayField(i:any) { return i.get('wpDisplayField'); }
export function upgradeFactorywpNotificationsService(i:any) { return i.get('wpNotificationsService'); }
export function upgradeFactorywpListChecksumService(i:any) { return i.get('wpListChecksumService'); }
export function upgradeFactorywpRelationsHierarchyService(i:any) { return i.get('wpRelationsHierarchyService'); }
export function upgradeFactorywpFiltersService(i:any) { return i.get('wpFiltersService'); }
export function upgradeFactoryloadingIndicator(i:any) { return i.get('loadingIndicator'); }
export function upgradeFactoryapiWorkPackages(i:any) { return i.get('apiWorkPackages'); }
export function upgradeFactoryauthorisationService(i:any) { return i.get('authorisationService'); }
export function upgradeFactoryConfigurationService(i:any) { return i.get('ConfigurationService'); }
export function upgradeFactorycurrentProject(i:any) { return i.get('currentProject'); }
export function upgradeFactoryRootDm(i:any) { return i.get('RootDm'); }
export function upgradeFactoryQueryDm(i:any) { return i.get('QueryDm'); }
export function upgradeFactoryqueryMenu(i:any) { return i.get('queryMenu'); }
export function upgradeFactoryfirstRoute(i:any) { return i.get('firstRoute'); }
export function upgradeFactoryPathHelper(i:any) { return i.get('PathHelper'); }
export function upgradeFactorywpActivity(i:any) { return i.get('wpActivity'); }
export function upgradeFactoryHookService(i:any) { return i.get('HookService'); }
export function upgradeFactoryUrlParamsHelper(i:any) { return i.get('UrlParamsHelper'); }
