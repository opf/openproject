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
import { utils } from '@xeokit/xeokit-sdk/dist/xeokit-sdk.es';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { IFCGonDefinition } from '../pages/viewer/ifc-models-data.service';

/**
 * Default server client which loads content via HTTP from the file system.
 */
export class XeokitServer {
  private ifcModels:IFCGonDefinition;
  /**
   *
   * @param config
   * @param.config.pathHelper instance of PathHelperService.
   */
  constructor(private pathHelper:PathHelperService) {
    this.ifcModels = window.gon.ifc_models;
  }

  /**
   * Gets the manifest of all projects.
   * @param done
   * @param error
   */
  getProjects(done:Function, _error:Function) {
    done({ projects: this.ifcModels.projects });
  }

  /**
   * Gets a manifest for a project.
   * @param projectId
   * @param done
   * @param error
   */
  getProject(projectData:any, done:Function, _error:Function) {
    var manifestData = {
      id: projectData[0].id,
      name: projectData[0].name,
      models: this.ifcModels.models,
      viewerContent: {
        modelsLoaded: this.ifcModels.shown_models
      },
      viewerConfigs: {}
    };

    done(manifestData);
  }

  /**
   * Gets geometry for a model within a project.
   * @param projectId
   * @param modelId
   * @param done
   * @param error
   */
  getGeometry(projectId:string, modelId:number, done:Function, error:Function) {
    const attachmentId = this.ifcModels.xkt_attachment_ids[modelId];
    console.log(`Loading model geometry for: ${attachmentId}`);
    utils.loadArraybuffer(this.pathHelper.attachmentContentPath(attachmentId), done, error);
  }
}
