import {utils} from "@xeokit/xeokit-sdk/src/viewer/scene/utils";
/**
 * Default server client which loads content via HTTP from the file system.
 */
class XeokitServer {

  /**
   *
   * @param cfg
   * @param.cfg.dataDir Base directory for content.
   */
  constructor(cfg = {}) {
    this._dataDir = cfg.dataDir || "";
  }

  /**
   * Gets the manifest of all projects.
   * @param done
   * @param error
   */
  getProjects(done, _error) {
    done({ projects: window.gon.ifc_models.projects });
  }

  /**
   * Gets a manifest for a project.
   * @param projectId
   * @param done
   * @param error
   */
  getProject(projectData, done, _error) {
    var manifestData = {
      id: projectData[0].id,
      name: projectData[0].name,
      models: window.gon.ifc_models.models,
      viewerContent: {
        modelsLoaded: window.gon.ifc_models.shown_models
      },
      viewerConfigs: {
        saoEnabled: true // Needs to be enabled by default if we want to use it selectively on the available models.
      }
    };

    done(manifestData);
  }

  /**
   * Gets metadata for a model within a project.
   * @param projectId
   * @param modelId
   * @param done
   * @param error
   */
  getMetadata(_projectId, modelId, done, error) {
    const attachmentId = window.gon.ifc_models.metadata_attachment_ids[modelId];
    console.log(`Loading model metadata for: ${attachmentId}`);
    utils.loadJSON(this.attachmentUrl(attachmentId), done, error);
  }

  /**
   * Gets geometry for a model within a project.
   * @param projectId
   * @param modelId
   * @param done
   * @param error
   */
  getGeometry(projectId, modelId, done, error) {
    const attachmentId = window.gon.ifc_models.xkt_attachment_ids[modelId];
    console.log(`Loading model geometry for: ${attachmentId}`);
    utils.loadArraybuffer(this.attachmentUrl(attachmentId), done, error);
  }

  attachmentUrl(attachmentId) {
    return "/api/v3/attachments/" + attachmentId + "/content";
  }
}

export {XeokitServer};