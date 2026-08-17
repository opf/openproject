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

export interface CKEditorEvent {
  stop:() => void;
}

export interface CKEditorListenOptions {
  priority:string;
}

export interface CKEditorDomEventData {
  altKey:boolean;
  shiftKey:boolean;
  ctrlKey:boolean;
  metaKey:boolean;
  keyCode:number;
}

export interface ICKEditorInstance {
  id:string;

  state:string;

  getData(options?:{ trim:boolean }):string;

  setData(content:string):void;

  destroy():void;

  enableReadOnlyMode(lockId:string):void;

  disableReadOnlyMode(lockId:string):void;

  on(event:string, callback:() => unknown):void;

  listenTo(node:unknown, key:string, callback:(evt:CKEditorEvent, data:CKEditorDomEventData) => unknown, options:CKEditorListenOptions):void;

  model:{
    on(ev:string, callback:() => unknown):void
    fire(ev:string, data:unknown):void
    document:{
      on(ev:string, callback:() => unknown):void
    };
  };
  editing:{
    view:{
      focus():void;
      document:Document
    }
  };
  config:any;
  ui:any;
  element:HTMLElement;
}

export interface ICKEditorStatic {
  create(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;

  createCustomized(el:string|HTMLElement, config?:any):Promise<ICKEditorInstance>;

  defaultConfig?:{ toolbar?:{ items:string[] } };
}

export type ICKEditorState = 'initializing'|'ready'|'crashed'|'crashedPermanently'|'destroyed';

export interface ICKEditorError {
  message:string;
  stack:any;
}

export interface ICKEditorWatchdog {
  setCreator(callback:(elementOrData:any, editorConfig:any) => Promise<ICKEditorInstance>):void;

  setDestructor(callback:(editor:ICKEditorInstance) => void):void;

  create(elementOrData:any, editorConfig:any):Promise<ICKEditorInstance>;

  destroy():void;

  on(listener:'stateChange', callback:() => void):void;

  on(listener:'error', callback:(evt:Event, args:{ error:ICKEditorError }) => void):void;

  editor:ICKEditorInstance;
  state:ICKEditorState;
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
