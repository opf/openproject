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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  ICKEditorMacroType,
  ICKEditorType,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import type {
  CKEditorDomEventData,
  CKEditorEvent,
  CKEditorListenOptions,
  ICKEditorContext as ICKEditorBuildContext,
  ICKEditorError,
  ICKEditorInstance,
  ICKEditorStatic,
  ICKEditorState,
  ICKEditorWatchdog,
} from 'core-vendor/ckeditor/types';

export type {
  CKEditorDomEventData,
  CKEditorEvent,
  CKEditorListenOptions,
  ICKEditorError,
  ICKEditorInstance,
  ICKEditorStatic,
  ICKEditorState,
  ICKEditorWatchdog,
};

export interface ICKEditorContext extends Omit<ICKEditorBuildContext, 'resource'|'macros'> {
  // Editor type to setup
  type:ICKEditorType;
  // Hal Resource to pass into ckeditor
  resource?:HalResource;
  // If available, field name of the edit
  field?:string;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all.
  macros?:ICKEditorMacroType;
}

declare global {
  interface HTMLElement {
    ckeditorInstance?:ICKEditorInstance;
  }
}
