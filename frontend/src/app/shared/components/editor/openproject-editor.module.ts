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

import { APP_INITIALIZER, Injector, NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import {
  CkeditorAugmentedTextareaComponent,
} from 'core-app/shared/components/editor/components/ckeditor-augmented-textarea/ckeditor-augmented-textarea.component';
import { OpCkeditorComponent } from 'core-app/shared/components/editor/components/ckeditor/op-ckeditor.component';
import { CKEditorSetupService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import { CKEditorPreviewService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-preview.service';
import { EditorMacrosService } from 'core-app/shared/components/modals/editor/editor-macros.service';
import {
  WikiIncludePageMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-wiki-include-page-modal/wiki-include-page-macro.modal';
import {
  ChildPagesMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-child-pages-modal/child-pages-macro.modal';
import {
  CodeBlockMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-code-block-modal/code-block-macro.modal';

export function initializeServices(injector:Injector) {
  return () => {
    const ckeditorService = injector.get(CKEditorSetupService);
    ckeditorService.initialize();
  };
}

@NgModule({
  imports: [
    FormsModule,
    CommonModule,
    OpenprojectAttachmentsModule,
    OpenprojectModalModule,
  ],
  providers: [
    // CKEditor
    EditorMacrosService,
    CKEditorSetupService,
    CKEditorPreviewService,
    {
      provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true,
    },
  ],
  exports: [
    CkeditorAugmentedTextareaComponent,
    OpCkeditorComponent,
  ],
  declarations: [
    // CKEditor and Macros
    CkeditorAugmentedTextareaComponent,
    OpCkeditorComponent,
    WikiIncludePageMacroModalComponent,
    CodeBlockMacroModalComponent,
    ChildPagesMacroModalComponent,
  ],
})
export class OpenprojectEditorModule {
  constructor(injector:Injector) {
  }
}
