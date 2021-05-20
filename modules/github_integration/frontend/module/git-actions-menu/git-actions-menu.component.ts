//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import copy from 'copy-text-to-clipboard';
import { Component, Inject, Input } from '@angular/core';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { GitActionsService } from '../git-actions/git-actions.service';
import { OPContextMenuComponent } from 'core-app/components/op-context-menu/op-context-menu.component';
import {
  OpContextMenuLocalsMap,
  OpContextMenuLocalsToken
} from 'core-app/components/op-context-menu/op-context-menu.types';
import { ITab } from "core-app/modules/plugins/linked/openproject-github_integration/typings";


@Component({
  selector: 'op-git-actions-menu',
  templateUrl: './git-actions-menu.template.html',
  styleUrls: [
    './styles/git-actions-menu.sass'
  ]
})
export class GitActionsMenuComponent extends OPContextMenuComponent {
  @Input() public workPackage:WorkPackageResource;

  public text = {
    title: this.I18n.t('js.github_integration.tab_header.git_actions.title'),
    copyButtonHelpText: this.I18n.t('js.github_integration.tab_header.git_actions.copy_button_help'),
    copyResult: {
      success: this.I18n.t('js.github_integration.tab_header.git_actions.copy_success'),
      error: this.I18n.t('js.github_integration.tab_header.git_actions.copy_error')
    }
  };

  public lastCopyResult:string = this.text.copyResult.success;
  public showCopyResult:boolean = false;

  public tabs:ITab[] = [
    {
      id: 'branch',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.branch'),
      help: this.I18n.t('js.github_integration.tab_header.git_actions.branch_help'),
      lines: 1,
      textToCopy: () => this.gitActions.branchName(this.workPackage)
    },
    {
      id: 'message',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.message'),
      help: this.I18n.t('js.github_integration.tab_header.git_actions.message_help'),
      lines: 6,
      textToCopy: () => this.gitActions.commitMessage(this.workPackage)
    },
    {
      id: 'command',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.cmd'),
      help: this.I18n.t('js.github_integration.tab_header.git_actions.cmd_help'),
      lines: 6,
      textToCopy: () => this.gitActions.gitCommand(this.workPackage)
    },
  ];

  public selectedTab:ITab = this.tabs[0];

  constructor(@Inject(OpContextMenuLocalsToken)
              public locals:OpContextMenuLocalsMap,
              readonly I18n:I18nService,
              readonly gitActions:GitActionsService) {
    super(locals);
    this.workPackage = this.locals.workPackage;
  }

  public onCopyButtonClick():void {
    const success = this.copySelectedTabText();

    if (success) {
      this.lastCopyResult = this.text.copyResult.success;
    } else {
      this.lastCopyResult = this.text.copyResult.error;
    }
    this.showCopyResult = true;
    window.setTimeout(() => {
      this.showCopyResult = false;
    }, 2000);
  }

  public copySelectedTabText():boolean {
    return copy(this.selectedTab.textToCopy());
  }
}
