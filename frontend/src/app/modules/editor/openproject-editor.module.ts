// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {NgModule} from '@angular/core';
import {WikiIncludePageMacroModal} from 'core-components/modals/editor/macro-wiki-include-page-modal/wiki-include-page-macro.modal';
import {CodeBlockMacroModal} from 'core-components/modals/editor/macro-code-block-modal/code-block-macro.modal';
import {ChildPagesMacroModal} from 'core-components/modals/editor/macro-child-pages-modal/child-pages-macro.modal';
import {CkeditorAugmentedTextareaComponent} from 'core-app/ckeditor/ckeditor-augmented-textarea.component';
import {OpenprojectAttachmentsModule} from 'core-app/modules/attachments/openproject-attachments.module';
import {OpCkeditorComponent} from 'core-app/modules/common/ckeditor/op-ckeditor.component';
import {FormsModule} from '@angular/forms';
import {EditorMacrosService} from 'core-components/modals/editor/editor-macros.service';
import {CKEditorSetupService} from 'core-app/modules/common/ckeditor/ckeditor-setup.service';
import {CKEditorPreviewService} from 'core-app/modules/common/ckeditor/ckeditor-preview.service';
import {CommonModule} from "@angular/common";

@NgModule({
  imports: [
    FormsModule,
    CommonModule,
    OpenprojectAttachmentsModule
  ],
  providers: [
    // CKEditor
    EditorMacrosService,
    CKEditorSetupService,
    CKEditorPreviewService,
  ],
  exports: [
    CkeditorAugmentedTextareaComponent,
    OpCkeditorComponent,
  ],
  declarations: [
    // CKEditor and Macros
    CkeditorAugmentedTextareaComponent,
    OpCkeditorComponent,
    WikiIncludePageMacroModal,
    CodeBlockMacroModal,
    ChildPagesMacroModal,
  ]
})
export class OpenprojectEditorModule {
}
