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

import type { AutosaveConfig } from '@ckeditor/ckeditor5-autosave';
import type { LinkConfig } from '@ckeditor/ckeditor5-link';
import type { EditorConfig } from '@ckeditor/ckeditor5-core';
import type { DecoupledEditor } from '@ckeditor/ckeditor5-editor-decoupled';
import type { EditorWatchdog } from '@ckeditor/ckeditor5-watchdog';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  ICKEditorMacroType,
  ICKEditorType,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';

export type ICKEditorInstance = DecoupledEditor;

export type ICKEditorWatchdog = EditorWatchdog<ICKEditorInstance>;

export type ICKEditorStatic = typeof DecoupledEditor & {
  createCustomized(el:string|HTMLElement, config:OpenProjectEditorConfig):Promise<ICKEditorInstance>;
};

export interface OpenProjectEditorConfig extends EditorConfig {
  autosave?:AutosaveConfig;
  link?:LinkConfig;
  openProject:{
    context:ICKEditorContext;
    helpURL:string;
    pluginContext:unknown;
  };
  storageKey?:string;
}

export interface ICKEditorContext {
  // Editor type to setup
  type:ICKEditorType;
  // Hal Resource to pass into ckeditor
  resource?:HalResource;
  // If available, field name of the edit
  field?:string;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all
  macros?:ICKEditorMacroType;
  // Additional options like the text orientation of the editors content
  options?:{
    rtl?:boolean;
  };
  // context link to append on preview requests
  previewContext?:string;
  // disabled specific mentions
  disabledMentions?:['user'|'work_package'];
  // overrides the default storage key for revisions
  storageKey?:string;
}

declare global {
  interface HTMLElement {
    ckeditorInstance?:ICKEditorInstance;
  }
}
