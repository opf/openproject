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

export interface IEditorWithContent {
  state:string;
  getData():string;
  once(event:'destroy', callback:() => void):void;
  enableReadOnlyMode(lockId:string):void;
  disableReadOnlyMode(lockId:string):void;
  data:{
    processor:{ toView(markdown:string):unknown };
    toModel(viewFragment:unknown):unknown;
  };
  model:{
    document:{ getRoot():unknown };
    createRangeIn(element:unknown):unknown;
    change(callback:() => void):void;
    insertContent(content:unknown, selectable:unknown):void;
  };
}

// Replaces the whole document through the model so the editor records the
// change as a single undo step. editor.setData() would drop the undo stack.
export function replaceEditorContent(editor:IEditorWithContent, markdown:string):void {
  const viewFragment = editor.data.processor.toView(markdown);
  const modelFragment = editor.data.toModel(viewFragment);

  editor.model.change(() => {
    const root = editor.model.document.getRoot();
    editor.model.insertContent(modelFragment, editor.model.createRangeIn(root));
  });
}
