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

export interface DatePickerCreateResponse {
  duration:number|null;
  startDate:string|null;
  dueDate:string|null;
  includeNonWorkingDays:boolean;
  scheduleManually:boolean;
}

export interface ProgressCreateResponse {
  estimatedTime:string|null;
  remainingTime:string|null;
  percentageDone:number|null;
}

export type ModalCreateResponse = DatePickerCreateResponse|ProgressCreateResponse;

function isRecord(value:unknown):value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isNullableString(value:unknown):value is string|null {
  return value === null || typeof value === 'string';
}

function isNullableNumber(value:unknown):value is number|null {
  return value === null || typeof value === 'number';
}

export function isDatePickerCreateResponse(value:unknown):value is DatePickerCreateResponse {
  return isRecord(value)
    && isNullableNumber(value.duration)
    && isNullableString(value.startDate)
    && isNullableString(value.dueDate)
    && typeof value.includeNonWorkingDays === 'boolean'
    && typeof value.scheduleManually === 'boolean';
}

export function isProgressCreateResponse(value:unknown):value is ProgressCreateResponse {
  return isRecord(value)
    && isNullableString(value.estimatedTime)
    && isNullableString(value.remainingTime)
    && isNullableNumber(value.percentageDone);
}
