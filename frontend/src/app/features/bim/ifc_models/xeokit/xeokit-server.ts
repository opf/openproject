// @ts-expect-error xeokit-sdk has no module
// eslint-disable-next-line import/no-extraneous-dependencies
import { utils } from '@xeokit/xeokit-sdk/dist/xeokit-sdk.es';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IfcModelsDataService } from '../pages/viewer/ifc-models-data.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';

/**
 * Default server client which loads content via HTTP from the file system.
 */
export class XeokitServer {
  /**
   *
   * @param config
   * @param pathHelper instance of PathHelperService.
   * @param ifcModelsDataService instance of IfcModelsDataService.
   */
  constructor(
    private pathHelper:PathHelperService,
    private ifcModelsDataService:IfcModelsDataService,
  ) {
  }

  /**
   * Gets the manifest of all projects.
   */
  getProjects(done:(result:unknown) => void, _error:() => void) {
    done({ projects: this.ifcModelsDataService.projects });
  }

  /**
   * Gets a manifest for a project.
   * @param projectId
   * @param done
   * @param _error
   */
  getProject(projectId:string, done:(json:unknown) => void, _error:() => void) {
    const projectDefinition = this.ifcModelsDataService.projects.find((p) => p.id === projectId);
    if (projectDefinition === undefined) {
      throw new Error(`unknown project id '${projectId}'`);
    }

    const manifestData = {
      id: projectDefinition.id,
      name: projectDefinition.name,
      models: this.ifcModelsDataService.models,
      viewerContent: {
        modelsLoaded: this.ifcModelsDataService.shownModels,
      },
      viewerConfigs: {},
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
  getGeometry(projectId:string, modelId:number, done:() => void, error:() => void) {
    const attachmentId = this.ifcModelsDataService.xktAttachmentIds[modelId];
    debugLog(`Loading model geometry for: ${attachmentId}`);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
    utils.loadArraybuffer(this.pathHelper.attachmentContentPath(attachmentId), done, error);
  }
}
