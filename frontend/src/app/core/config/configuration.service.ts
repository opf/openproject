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
import { firstValueFrom } from 'rxjs';
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
    return this.configuration.userPreferences.commentSortDescending;
  }

  public disableKeyboardShortcuts():boolean {
    return this.configuration.userPreferences.disableKeyboardShortcuts;
  }

  public warnOnLeavingUnsaved():boolean {
    return this.configuration.userPreferences.warnOnLeavingUnsaved;
  }

  public autoHidePopups():boolean {
    return this.configuration.userPreferences.autoHidePopups;
  }

  public isTimezoneSet():boolean {
    return !!this.timezone();
  }

  public isDefaultTimezoneSet():boolean {
    return !!this.defaultTimezone();
  }

  public timezone():string {
    return this.configuration.userPreferences.timeZone;
  }

  public isDirectUploads():boolean {
    return !!this.prepareAttachmentURL;
  }

  public get prepareAttachmentURL():string|undefined {
    return this.configuration.prepareAttachment?.href;
  }

  public get maximumAttachmentFileSize():number {
    return this.configuration.maximumAttachmentFileSize;
  }

  public get maximumApiV3PageSize():number {
    return this.configuration.maximumAPIV3PageSize;
  }

  public get perPageOptions():number[] {
    return this.configuration.perPageOptions;
  }

  public get allowedLinkProtocols():string[]|null {
    return this.configuration.allowedLinkProtocols ?? null;
  }

  public dateFormatPresent():boolean {
    return !!this.dateFormat();
  }

  public dateFormat():string {
    return this.configuration.dateFormat ?? '';
  }

  public durationFormat():DurationFormat {
    return this.configuration.durationFormat;
  }

  public hoursPerDay():number {
    return this.configuration.hoursPerDay;
  }

  public daysPerMonth():number {
    return this.configuration.daysPerMonth;
  }

  public timeFormatPresent():boolean {
    return !!this.timeFormat();
  }

  public timeFormat():string {
    return this.configuration.timeFormat ?? '';
  }

  public defaultTimezone():string {
    return this.configuration.userDefaultTimezone ?? '';
  }

  public startOfWeek():number {
    const startOfWeek = this.configuration.startOfWeek;
    if (startOfWeek !== null) {
      return startOfWeek;
    }
    return moment.localeData(I18n.locale).firstDayOfWeek();
  }

  public get wikisAvailable():boolean {
    return this.configuration.wikisAvailable;
  }

  public get hostName():string {
    return this.configuration.hostName;
  }

  public get activeFeatureFlags():string[] {
    return this.configuration.activeFeatureFlags;
  }

  public get availableFeatures():string[] {
    return this.configuration.availableFeatures;
  }

  public get triallingFeatures():string[] {
    return this.configuration.triallingFeatures;
  }

  private async loadConfiguration():Promise<void> {
    this.configuration = await firstValueFrom(this.apiV3Service.configuration.get());
  }
}
