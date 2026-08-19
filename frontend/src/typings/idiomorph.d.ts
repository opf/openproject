/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

declare module 'idiomorph' {
  type ConfigHeadStyle = 'merge'|'append'|'morph'|'none';

  interface ConfigHead {
    style?:ConfigHeadStyle;
    block?:boolean;
    ignore?:boolean;
    shouldPreserve?:(element:Element) => boolean;
    shouldReAppend?:(element:Element) => boolean;
    shouldRemove?:(element:Element) => boolean;
    afterHeadMorphed?:(element:Element, data:{ added:Node[]; kept:Element[]; removed:Element[] }) => void;
  }

  interface ConfigCallbacks {
    beforeNodeAdded?:(node:Node) => boolean;
    afterNodeAdded?:(node:Node) => void;
    beforeNodeMorphed?:(oldElement:Element, newElement:Node) => boolean;
    afterNodeMorphed?:(oldElement:Element, newElement:Node) => void;
    beforeNodeRemoved?:(element:Element) => boolean;
    afterNodeRemoved?:(element:Element) => void;
    beforeAttributeUpdated?:(attributeName:string, element:Element, updateType:'update'|'remove') => boolean;
  }

  export interface Config {
    morphStyle?:'outerHTML'|'innerHTML';
    ignoreActive?:boolean;
    ignoreActiveValue?:boolean;
    restoreFocus?:boolean;
    callbacks?:ConfigCallbacks;
    head?:ConfigHead;
  }

  type NoOp = () => void;

  interface ConfigHeadInternal {
    style:ConfigHeadStyle;
    block?:boolean;
    ignore?:boolean;
    shouldPreserve?:((element:Element) => boolean)|NoOp;
    shouldReAppend?:((element:Element) => boolean)|NoOp;
    shouldRemove?:((element:Element) => boolean)|NoOp;
    afterHeadMorphed?:((element:Element, data:{ added:Node[], kept:Element[], removed:Element[] }) => void )| NoOp;
  }

  interface ConfigCallbacksInternal {
      beforeNodeAdded?:(node:Node) => boolean|NoOp,
      afterNodeAdded?:(node:Node) => undefined|NoOp,
      beforeNodeMorphed?:(oldElement:Node,newElement:Node) => boolean|NoOp,
      afterNodeMorphed?:(oldElement:Node,newElement:Node) => undefined|NoOp,
      beforeNodeRemoved?:(element:Node) => boolean|NoOp,
      afterNodeRemoved?:(element:Node) => undefined|NoOp,
      beforeAttributeUpdated?(attributeName:string, element:Element, updateType:'update'|'remove'):boolean|NoOp
  }

  interface ConfigInternal {
    morphStyle:'outerHTML'|'innerHTML',
    ignoreActive?:boolean ,
    ignoreActiveValue?:boolean ,
    restoreFocus?:boolean ,
    callbacks?:ConfigCallbacksInternal ,
    head?:ConfigHeadInternal
  }

  export const Idiomorph:{
    morph(ldNode:Element|Document, newContent?:Element|Node|HTMLCollection|Node[]|string|null, options?:Config);
    defaults:ConfigInternal;
  };

  export { Idiomorph };
}
