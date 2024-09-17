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

  getData(options:{ trim:boolean }):string;

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
}
