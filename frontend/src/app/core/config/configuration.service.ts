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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import moment from 'moment';

import { ConfigurationResource } from 'core-app/features/hal/resources/configuration-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { type DurationFormat } from 'core-app/shared/helpers/chronic_duration';

@Injectable({ providedIn: 'root' })
export class ConfigurationService {
  private readonly apiV3Service = inject(ApiV3Service);

  // fetches configuration from the ApiV3 endpoint
  // TODO: this currently saves the request between page reloads,
  // but could easily be stored in localStorage
  private configuration:ConfigurationResource;

  public initialize():Promise<void> {
    return this.loadConfiguration();
  }

  public commentsSortedInDescendingOrder():boolean {
    return this.userPreference('commentSortDescending');
  }

  public disableKeyboardShortcuts():boolean {
    return this.userPreference('disableKeyboardShortcuts');
  }

  public warnOnLeavingUnsaved():boolean {
    return this.userPreference('warnOnLeavingUnsaved');
  }

  public autoHidePopups():boolean {
    return this.userPreference('autoHidePopups');
  }

  public isTimezoneSet():boolean {
    return !!this.timezone();
  }

  public isDefaultTimezoneSet():boolean {
    return !!this.defaultTimezone();
  }

  public timezone():string {
    return this.userPreference('timeZone');
  }

  public isDirectUploads():boolean {
    return !!this.prepareAttachmentURL;
  }

  public get prepareAttachmentURL():string {
    return _.get(this.configuration, ['prepareAttachment', 'href']) as string;
  }

  public get maximumAttachmentFileSize():number {
    return this.systemPreference('maximumAttachmentFileSize');
  }

  public get maximumApiV3PageSize():number {
    return this.systemPreference('maximumAPIV3PageSize');
  }

  public get perPageOptions():number[] {
    return this.systemPreference('perPageOptions');
  }

  public get allowedLinkProtocols():string[]|null {
    return this.systemPreference('allowedLinkProtocols') || null;
  }

  public dateFormatPresent():boolean {
    return !!this.systemPreference('dateFormat');
  }

  public dateFormat():string {
    return this.systemPreference('dateFormat');
  }

  public durationFormat():DurationFormat {
    return this.systemPreference('durationFormat');
  }

  public hoursPerDay():number {
    return this.systemPreference('hoursPerDay');
  }

  public hoursPerWeek():number {
    return this.systemPreference('hoursPerWeek');
  }

  public daysPerMonth():number {
    return this.systemPreference('daysPerMonth');
  }

  public timeFormatPresent():boolean {
    return !!this.systemPreference('timeFormat');
  }

  public timeFormat():string {
    return this.systemPreference('timeFormat');
  }

  public defaultTimezone():string {
    return this.systemPreference('userDefaultTimezone');
  }

  public startOfWeekPresent():boolean {
    return !!this.systemPreference('startOfWeek');
  }

  public startOfWeek():number {
    if (this.startOfWeekPresent()) {
      return this.systemPreference('startOfWeek');
    }
    return moment.localeData(I18n.locale).firstDayOfWeek();
  }

  public get wikisAvailable():boolean {
    return this.systemPreference('wikisAvailable');
  }

  public get hostName():string {
    return this.systemPreference('hostName');
  }

  public get activeFeatureFlags():string[] {
    return this.systemPreference<string[]>('activeFeatureFlags');
  }

  public get availableFeatures():string[] {
    return this.systemPreference<string[]>('availableFeatures');
  }

  public get triallingFeatures():string[] {
    return this.systemPreference<string[]>('triallingFeatures');
  }

  private loadConfiguration() {
    return this
      .apiV3Service
      .configuration
      .get()
      .toPromise()
      .then((configuration:ConfigurationResource) => {
        this.configuration = configuration;
      });
  }

  private userPreference<T>(pref:string):T {
    return _.get(this.configuration, ['userPreferences', pref]) as T;
  }

  private systemPreference<T>(pref:string):T {
    return _.get(this.configuration, pref) as T;
  }
}
