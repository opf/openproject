//------------------------------------------------------------------------------------------------------------------
// Import the modules we need for this example
//------------------------------------------------------------------------------------------------------------------
import {Viewer} from "../../../../vendor/xeokit-sdk/src/viewer/Viewer.js";
import {XKTLoaderPlugin} from "../../../../vendor/xeokit-sdk/src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
import InspireTree from "inspire-tree";
import InspireTreeDOM from "inspire-tree-dom";
// import {NavCubePlugin} from "../src/plugins/NavCubePlugin/NavCubePlugin.js";
//------------------------------------------------------------------------------------------------------------------
// Create a Viewer, arrange the camera, tweak xraying and highlight materials
//------------------------------------------------------------------------------------------------------------------

export class XeokitViewer {
  constructor(ifcModelId, xktFileUrl, metadataFileUrl) {
    const viewer = new Viewer({
      canvasId: 'xeokit-model-canvas-' + ifcModelId,
      transparent: true
    });
    const cameraControl = viewer.cameraControl;
    const scene = viewer.scene;
    const cameraFlight = viewer.cameraFlight;
    cameraControl.panToPointer = true;
    cameraControl.doublePickFlyTo = true;
    cameraFlight.duration = 1.0;
    cameraFlight.fitFOV = 25;
    viewer.camera.eye = [-2.56, 8.38, 8.27];
    viewer.camera.look = [13.44, 3.31, -14.83];
    viewer.camera.up = [0.10, 0.98, -0.14];
    viewer.scene.xrayMaterial.fillAlpha = 0.1;
    viewer.scene.xrayMaterial.fillColor = [0, 0, 0];
    viewer.scene.xrayMaterial.edgeAlpha = 0.4;
    viewer.scene.xrayMaterial.edgeColor = [0, 0, 0];
    viewer.scene.highlightMaterial.fill = false;
    viewer.scene.highlightMaterial.fillAlpha = 0.3;
    viewer.scene.highlightMaterial.edgeColor = [1, 1, 0];

    const xktLoader = new XKTLoaderPlugin(viewer);
    const model = xktLoader.load({
      id: "xeokit-model-" + ifcModelId,
      src: xktFileUrl,
      metaModelSrc: metadataFileUrl,
      edges: true
    });
    //------------------------------------------------------------------------------------------------------------------
    // Mouse over entities to highlight them
    //------------------------------------------------------------------------------------------------------------------
    var lastEntity = null;
    viewer.scene.input.on("mousemove", function (coords) {
      var hit = viewer.scene.pick({
        canvasPos: coords
      });
      if (hit) {
        if (!lastEntity || hit.entity.id !== lastEntity.id) {
          if (lastEntity) {
            lastEntity.highlighted = false;
          }
          lastEntity = hit.entity;
          hit.entity.highlighted = true;
        }
      } else {
        if (lastEntity) {
          lastEntity.highlighted = false;
          lastEntity = null;
        }
      }
    });
    //------------------------------------------------------------------------------------------------------------------
    // When model loaded, create a tree view that toggles object xraying
    //------------------------------------------------------------------------------------------------------------------
    const t0 = performance.now();
    model.on("loaded", function () {
      const t1 = performance.now();
      // Builds tree view data from MetaModel
      var createData = function (metaModel) {
        const data = [];
        function visit(expand, data, metaObject) {
          if (!metaObject) {
            return;
          }
          var child = {
            id: metaObject.id,
            text: metaObject.name
          };
          data.push(child);
          const children = metaObject.children;
          if (children) {
            child.children = [];
            for (var i = 0, len = children.length; i < len; i++) {
              visit(true, child.children, children[i]);
            }
          }
        }
        visit(true, data, metaModel.rootMetaObject);
        return data;
      };
      // Get MetaModel we loaded for our model
      const modelId = model.id;
      const metaModel = viewer.metaScene.metaModels[modelId];
      // Create the tree view
      var treeView = new InspireTree({
        selection: {
          autoSelectChildren: true,
          autoDeselect: true,
          mode: 'checkbox'
        },
        checkbox: {
          autoCheckChildren: true
        },
        data: createData(metaModel)
      });
      new InspireTreeDOM(treeView, {
        target: document.getElementById(`xeokit-tree-panel-${ifcModelId}`)
      });
      // Initialize the tree view once loaded
      treeView.on('model.loaded', function () {
        treeView.select();
        treeView.model.expand();
        treeView.model[0].children[0].expand();
        treeView.model[0].children[0].children[0].expand();
        treeView.on('node.selected', function (event, node) {
          const objectId = event.id;
          viewer.scene.setObjectsXRayed(objectId, false);
          viewer.scene.setObjectsPickable(objectId, true);
        });
        treeView.on('node.deselected', function (event, node) {
          const objectId = event.id;
          viewer.scene.setObjectsXRayed(objectId, true);
          viewer.scene.setObjectsPickable(objectId, false);
        });
      });
    });
    scene.input.on("mouseclicked", function (coords) {
      var hit = scene.pick({
        canvasPos: coords
      });
      if (hit) {
        var entity = hit.entity;
        var metaObject = viewer.metaScene.metaObjects[entity.id];
        if (metaObject) {
          console.log(JSON.stringify(metaObject.getJSON(), null, "\t"));
        } else {
          const parent = entity.parent;
          if (parent) {
            metaObject = viewer.metaScene.metaObjects[parent.id];
            if (metaObject) {
              console.log(JSON.stringify(metaObject.getJSON(), null, "\t"));
            }
          }
        }
      }
    });
    return viewer;
  }
}

