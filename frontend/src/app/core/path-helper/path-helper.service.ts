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

import { Injectable } from '@angular/core';
import { ApiV3Paths } from './apiv3-paths';

@Injectable({ providedIn: 'root' })
export class PathHelperService {
  public readonly appBasePath = window.appBasePath || '';

  public readonly api = {
    v3: new ApiV3Paths(this.appBasePath),
  };

  public get staticBase() {
    return this.appBasePath;
  }

  public attachmentDownloadPath(attachmentIdentifier:string, slug:string|undefined) {
    const path = `${this.staticBase}/attachments/${attachmentIdentifier}`;

    if (slug) {
      return `${path}/${slug}`;
    }
    return path;
  }

  public attachmentContentPath(attachmentIdentifier:number|string) {
    return `${this.staticBase}/attachments/${attachmentIdentifier.toString()}/content`;
  }

  public attributeHelpTextsShowDialogPath(id:string|number) {
    return `${this.staticBase}/attribute_help_texts/${id.toString()}/show_dialog`;
  }

  public fileLinksPath():string {
    return `${this.api.v3.apiV3Base}/file_links`;
  }

  public bannerFramePath(feature:string, dismissable:boolean):string {
    return `${this.staticBase}/my/banner?feature_key=${feature}&dismissable=${dismissable.toString()}`;
  }

  public ifcModelsPath(projectIdentifier:string) {
    return `${this.staticBase}/projects/${projectIdentifier}/ifc_models`;
  }

  public ifcModelsNewPath(projectIdentifier:string) {
    return `${this.ifcModelsPath(projectIdentifier)}/new`;
  }

  public ifcModelsEditPath(projectIdentifier:string, modelId:number|string) {
    return `${this.ifcModelsPath(projectIdentifier)}/${modelId.toString()}/edit`;
  }

  public inviteUserPath(projectId:string|null) {
    const path = `${this.staticBase}/users/invite`;

    if (projectId) {
      return `${path}?user_invitation[project_id]=${projectId}`;
    }

    return path;
  }

  public ifcModelsDeletePath(projectIdentifier:string, modelId:number|string) {
    return `${this.ifcModelsPath(projectIdentifier)}/${modelId.toString()}`;
  }

  public bimDetailsPath(projectIdentifier:string, workPackageId:string, viewpoint:number|string|null = null) {
    let path = `${this.projectPath(projectIdentifier)}/bcf/details/${workPackageId}`;

    if (viewpoint !== null) {
      path += `?query_props=%7B"t"%3A"id%3Adesc"%2C"dr"%3A"splitCards"%7D&viewpoint=${viewpoint.toString()}`;
    }

    return path;
  }

  public highlightingCssPath() {
    return `${this.staticBase}/highlighting/styles`;
  }

  public forumPath(projectIdentifier:string, forumIdentifier:string) {
    return `${this.projectForumPath(projectIdentifier)}/${forumIdentifier}`;
  }

  public keyboardShortcutsHelpPath() {
    return `${this.staticBase}/help/keyboard_shortcuts`;
  }

  public messagePath(messageIdentifier:string) {
    return `${this.staticBase}/topics/${messageIdentifier}`;
  }

  public meetingPath(id:string):string {
    return `${this.staticBase}/meetings/${id}`;
  }

  public myPagePath() {
    return `${this.staticBase}/my/page`;
  }

  public myAccessTokensPath() {
    return `${this.staticBase}/my/access_tokens`;
  }

  public myNotificationsSettingsPath() {
    return `${this.staticBase}/my/notifications`;
  }

  public myPasswordConfirmationDialogPath() {
    return `${this.staticBase}/my/password_confirmation_dialog`;
  }

  public newsPath(newsId:string) {
    return `${this.staticBase}/news/${newsId}`;
  }

  public notificationsPath():string {
    return `${this.staticBase}/notifications`;
  }

  public notificationsDetailsPath(workPackageId:string, tab?:string):string {
    return `${this.notificationsPath()}/details/${workPackageId}${tab ? `/${tab}` : ''}`;
  }

  public loginPath() {
    return `${this.staticBase}/login`;
  }

  public projectsPath() {
    return `${this.staticBase}/projects`;
  }

  public projectsNewPath():string {
    return `${this.staticBase}/projects/new`;
  }

  public projectPath(projectIdentifier:string) {
    return `${this.projectsPath()}/${projectIdentifier}`;
  }

  public projectActivityPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/activity`;
  }

  public projectForumPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/forums`;
  }

  public projectCalendarPath(projectId:string) {
    return `${this.projectPath(projectId)}/calendars`;
  }

  public projectCreationWizardPath(projectId:string) {
    return `${this.projectPath(projectId)}/creation_wizard`;
  }

  public projectCreationWizardHelpTextPath(projectId:string, customFieldId:string) {
    return `${this.projectCreationWizardPath(projectId)}/help_text?custom_field_id=${customFieldId}`;
  }

  public projectTeamplannerPath(projectId:string) {
    return `${this.projectPath(projectId)}/team_planners`;
  }

  public ganttChartsPath(projectId:string|null) {
    if (projectId) {
      return `${this.projectPath(projectId)}/gantt`;
    }
    return `${this.staticBase}/gantt`;
  }

  public projectBCFPath(projectId:string) {
    return `${this.projectPath(projectId)}/bcf`;
  }

  public projectMembershipsPath(projectId:string) {
    return `${this.projectPath(projectId)}/members`;
  }

  public projectNewsPath(projectId:string) {
    return `${this.projectPath(projectId)}/news`;
  }

  public projectTimeEntriesPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/cost_reports`;
  }

  public projectWikiPath(projectId:string) {
    return `${this.projectPath(projectId)}/wiki`;
  }

  public projectWorkPackagePath(projectId:string, wpId:string|number) {
    return `${this.workPackagesPath(projectId)}/${wpId.toString()}`;
  }

  public workPackagesPath(projectId:string|null) {
    if (projectId) {
      return `${this.projectPath(projectId)}/work_packages`;
    }
    return `${this.staticBase}/work_packages`;
  }

  public workPackageNewPath():string {
    return `${this.staticBase}/work_packages/new`;
  }

  public projectWorkPackageNewPath(projectId:string) {
    return `${this.workPackagesPath(projectId)}/new`;
  }

  public boardsPath(projectIdentifier:string|null) {
    if (projectIdentifier) {
      return `${this.projectPath(projectIdentifier)}/boards`;
    }
    return `${this.staticBase}/boards`;
  }

  public newBoardsPath(projectIdentifier:string|null) {
    return `${this.boardsPath(projectIdentifier)}/new`;
  }

  public boardDetailsPath(projectIdentifier:string|null, boardId:string|number, workPackageId:string|number) {
    return `${this.boardsPath(projectIdentifier)}/${boardId}/details/${workPackageId}`;
  }

  public projectDashboardsPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/dashboards`;
  }

  public projectWidgetPath(projectIdentifier:string, widgetName:string) {
    return `${this.projectPath(projectIdentifier)}/widgets/${widgetName}`;
  }

  public timeEntriesPath(workPackageId:string|number) {
    const suffix = '/time_entries';

    if (workPackageId) {
      return this.workPackagePath(workPackageId) + suffix;
    }
    return this.staticBase + suffix; // time entries root path
  }

  public usersPath() {
    return `${this.staticBase}/users`;
  }

  public groupsPath() {
    return `${this.staticBase}/groups`;
  }

  public placeholderUsersPath() {
    return `${this.staticBase}/placeholder_users`;
  }

  public userPath(id:string|number) {
    return `${this.usersPath()}/${id.toString()}`;
  }

  public userHoverCardPath(id:string|number) {
    return `${this.usersPath()}/${id.toString()}/hover_card`;
  }

  public placeholderUserPath(id:string|number) {
    return `${this.placeholderUsersPath()}/${id.toString()}`;
  }

  public groupPath(id:string|number) {
    return `${this.groupsPath()}/${id.toString()}`;
  }

  public rolesPath() {
    return `${this.staticBase}/roles`;
  }

  public rolePath(id:string|number) {
    return `${this.rolesPath()}/${id.toString()}`;
  }

  public versionsPath() {
    return `${this.staticBase}/versions`;
  }

  public versionEditPath(id:string|number) {
    return `${this.staticBase}/versions/${id.toString()}/edit`;
  }

  public versionShowPath(id:string|number) {
    return `${this.staticBase}/versions/${id.toString()}`;
  }

  public widgetPath(widgetName:string) {
    return `${this.staticBase}/widgets/${widgetName}`;
  }

  public workPackagePath(id:string|number) {
    return `${this.staticBase}/work_packages/${id.toString()}`;
  }

  public genericWorkPackagePath(projectIdentifier:string|null, workPackageId:string|number, tab = 'activity') {
    if (projectIdentifier) {
      return `${this.projectWorkPackagePath(projectIdentifier, workPackageId)}/${tab}`;
    }

    return `${this.workPackagePath(workPackageId)}/${tab}`;
  }

  public workPackageShortPath(id:string|number) {
    return `${this.staticBase}/wp/${id.toString()}`;
  }

  public workPackageCopyPath(projectIdentifier:string|null, workPackageId:string|number) {
    if (projectIdentifier) {
      return `${this.workPackagesPath(projectIdentifier)}/${workPackageId}/copy`;
    }

    return `${this.workPackagePath(workPackageId)}/copy`;
  }

  public workPackageDetailsPath(projectIdentifier:string, workPackageId:string|number, tab?:string) {
    if (tab) {
      return `${this.projectWorkPackagePath(projectIdentifier, workPackageId)}/details/${tab}`;
    }

    return `${this.workPackagesPath(projectIdentifier)}/details/${workPackageId.toString()}`;
  }

  // Todo: Remove?
  public workPackageDetailsCopyPath(projectIdentifier:string, workPackageId:string|number) {
    return this.workPackageDetailsPath(projectIdentifier, workPackageId, 'copy');
  }

  public workPackageReminderModalBodyPath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/reminders/modal_body`;
  }

  public workPackageSharePath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/shares`;
  }

  public workPackageHoverCardPath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/hover_card`;
  }

  public workPackageProgressModalPath(workPackageId:string|number) {
    if (workPackageId === 'new') {
      return `${this.workPackagesPath(null)}/progress/new`;
    }

    return `${this.workPackagePath(workPackageId)}/progress/edit`;
  }

  public workPackageUpdateCounterPath(workPackageId:string|number, counter:string) {
    return `${this.workPackagePath(workPackageId)}/split_view/update_counter?counter=${counter}`;
  }

  public workPackageGetRelationsCounterPath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/split_view/get_relations_counter`;
  }

  public workPackageDatepickerDialogContentPath(workPackageId:string|number):string {
    if (workPackageId === 'new') {
      return `${this.workPackagesPath(null)}/date_picker/new`;
    }

    return `${this.workPackagePath(workPackageId)}/date_picker`;
  }

  // Work Package Bulk paths

  public workPackagesBulkEditPath() {
    return `${this.workPackagesPath(null)}/bulk/edit`;
  }

  public workPackagesBulkMovePath() {
    return `${this.workPackagesPath(null)}/move/new`;
  }

  public workPackagesBulkDuplicatePath() {
    return `${this.workPackagesBulkMovePath()}?copy=true`;
  }

  public workPackagesBulkDeletePath() {
    return `${this.workPackagesPath(null)}/bulk`;
  }

  public workPackagesBulkDeleteDialogPath(ids:string[], backUrl?:string) {
    const params = ids.map((id) => `ids[]=${encodeURIComponent(id)}`).join('&');
    const backParam = backUrl ? `&back_url=${encodeURIComponent(backUrl)}` : '';
    return `${this.workPackagesPath(null)}/bulk/delete_dialog?${params}${backParam}`;
  }

  public workPackagesBulkReassignmentPath() {
    return `${this.workPackagesPath(null)}/bulk/reassign`;
  }

  public textFormattingHelp() {
    return `${this.staticBase}/help/text_formatting`;
  }

  public jobStatusModalPath(jobId:string) {
    return `${this.staticBase}/job_statuses/${jobId}/dialog`;
  }

  public timeEntriesUserTimezoneCaption(userId:string) {
    return `${this.staticBase}/time_entries/users/${userId}/tz_caption`;
  }

  public timeEntriesWorkPackageActivity(workPackageId:string) {
    return `${this.staticBase}/time_entries/work_packages/${workPackageId}/time_entry_activities`;
  }

  public timeEntryDialog() {
    return `${this.staticBase}/time_entries/dialog`;
  }

  public timeEntryEditDialog(timeEntryId:string) {
    return `${this.staticBase}/time_entries/${timeEntryId}/dialog`;
  }

  public timeEntryWorkPackageDialog(workPackageId:string) {
    return `${this.workPackagePath(workPackageId)}/time_entries/dialog`;
  }

  public timeEntryProjectDialog(projectId:string) {
    return `${this.projectPath(projectId)}/time_entries/dialog`;
  }

  public timeEntryUpdate(timeEntryId:string) {
    return `${this.staticBase}/time_entries/${timeEntryId}`;
  }

  public myTimeTrackingRefresh(date:string, viewMode:string, mode:string) {
    return `${this.staticBase}/my/time-tracking/refresh?date=${date}&view_mode=${viewMode}&mode=${mode}`;
  }

  public previewCustomFieldRoleAssignmentDialog(customFieldId:number, roleId:number) {
    return `${this.staticBase}/admin/settings/project_custom_fields/${customFieldId}/role_assignment_preview_dialog?role_id=${roleId}`;
  }

  public homePath() {
    return `${this.staticBase}/`;
  }

  public externalRedirectPath(url:string) {
    return `${this.staticBase}/external_redirect?url=${encodeURIComponent(url)}`;
  }

  public wikiPageLinkMacro(providerId:string, pageIdentifier:string, turboFrameId:string) {
    const providerIdQuery = `provider_id=${encodeURIComponent(providerId)}`;
    const pageIdentifierQuery = `page_identifier=${encodeURIComponent(pageIdentifier)}`;
    const frameIdQuery = `turbo_frame_id=${encodeURIComponent(turboFrameId)}`;
    return `${this.staticBase}/wiki_page_link_macro/load?${providerIdQuery}&${pageIdentifierQuery}&${frameIdQuery}`;
  }

  public inlineExistingWikiPageDialog() {
    return `${this.staticBase}/wiki_page_link_macro/inline_existing_page_dialog`;
  }
}
