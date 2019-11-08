import {FrameContext} from './FrameContext.js';
import {RenderFlags} from './RenderFlags.js';
import {RenderBuffer} from './RenderBuffer.js';
import {math} from '../math/math.js';
import {stats} from '../stats.js';
import {WEBGL_INFO} from '../webglInfo.js';
import {Map} from "../utils/Map.js";
import {PickResult} from "./PickResult.js";
import {OcclusionTester} from "./OcclusionTester.js";

const TEST_TICKS = 20; // Do Occlusion test per this number of ticks.

/**
 * @private
 */
const Renderer = function (scene, options) {

    options = options || {};

    const frameCtx = new FrameContext();
    const canvas = scene.canvas.canvas;
    const gl = scene.canvas.gl;
    const canvasTransparent = options.transparent === true;

    const pickIDs = new Map({});

    var drawableTypeInfo = {};
    var drawables = {};

    const drawableListSorted = [];
    let drawableListSortedLen = 0;
    const shadowMeshLists = {};

    let drawableListDirty = true;
    let stateSortDirty = true;
    let imageDirty = true;
    let shadowsDirty = true;

    let blendOneMinusSrcAlpha = true;

    let pickBuf = null;
    let readPixelBuf = null;

    const bindOutputFrameBuffer = null;
    const unbindOutputFrameBuffer = null;

    this._occlusionTester = null; // Lazy-created in #addMarker()

    this.needStateSort = function () {
        stateSortDirty = true;
    };

    this.shadowsDirty = function () {
        shadowsDirty = true;
    };

    this.imageDirty = function () {
        imageDirty = true;
    };

    this.setBlendOneMinusSrcAlpha = function (value) {
        blendOneMinusSrcAlpha = value;
    };

    this.webglContextLost = function () {
    };

    this.webglContextRestored = function (gl) {
        if (pickBuf) {
            pickBuf.webglContextRestored(gl);
        }
        if (readPixelBuf) {
            readPixelBuf.webglContextRestored(gl);
        }
        imageDirty = true;
    };

    /**
     * Inserts a drawable into this renderer.
     *  @private
     */
    this.addDrawable = function (id, drawable) {
        var type = drawable.type;
        if (!type) {
            console.error("Renderer#addDrawable() : drawable with ID " + id + " has no 'type' - ignoring");
            return;
        }
        var drawableInfo = drawableTypeInfo[type];
        if (!drawableInfo) {
            drawableInfo = {
                type: drawable.type,
                count: 0,
                isStateSortable: drawable.isStateSortable,
                stateSortCompare: drawable.stateSortCompare,
                drawableMap: {},
                drawableList: [],
                lenDrawableList: 0
            };
            drawableTypeInfo[type] = drawableInfo;
        }
        drawableInfo.count++;
        drawableInfo.drawableMap[id] = drawable;
        drawables[id] = drawable;
        drawableListDirty = true;
    };

    /**
     * Removes a drawable from this renderer.
     *  @private
     */
    this.removeDrawable = function (id) {
        const drawable = drawables[id];
        if (!drawable) {
            console.error("Renderer#removeDrawable() : drawable not found with ID " + id + " - ignoring");
            return;
        }
        const type = drawable.type;
        const drawableInfo = drawableTypeInfo[type];
        if (--drawableInfo.count <= 0) {
            delete drawableTypeInfo[type];
        } else {
            delete drawableInfo.drawableMap[id];
        }
        delete drawables[id];
        drawableListDirty = true;
    };

    /**
     * Gets a unique pick ID for the given Pickable. A Pickable can be a {@link Mesh} or a {@link PerformanceMesh}.
     * @returns {Number} New pick ID.
     */
    this.getPickID = function (entity) {
        return pickIDs.addItem(entity);
    };

    /**
     * Released a pick ID for reuse.
     * @param {Number} pickID Pick ID to release.
     */
    this.putPickID = function (pickID) {
        pickIDs.removeItem(pickID);
    };

    /**
     * Clears the canvas.
     *  @private
     */
    this.clear = function (params) {
        params = params || {};
        const boundary = scene.viewport.boundary;
        gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);
        if (canvasTransparent) { // Canvas is transparent
            gl.clearColor(0, 0, 0, 0);
        } else {
            const color = params.ambientColor || scene.canvas.backgroundColor || this.lights.getAmbientColor();
            gl.clearColor(color[0], color[1], color[2], 1.0);
        }
        if (bindOutputFrameBuffer) {
            bindOutputFrameBuffer(params.pass);
        }
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT);
        if (unbindOutputFrameBuffer) {
            unbindOutputFrameBuffer(params.pass);
        }
    };

    /**
     * Renders inserted drawables.
     *  @private
     */
    this.render = function (params) {
        params = params || {};
        updateDrawlist();
        if (imageDirty || params.force) {
            draw(params);
            stats.frame.frameCount++;
            imageDirty = false;
        }
    };

    function updateDrawlist() { // Prepares state-sorted array of drawables from maps of inserted drawables
        if (drawableListDirty) {
            buildDrawableList();
            drawableListDirty = false;
            stateSortDirty = true;
        }
        if (stateSortDirty) {
            sortDrawableList();
            stateSortDirty = false;
            imageDirty = true;
        }
    }

    function buildDrawableList() {
        for (var type in drawableTypeInfo) {
            if (drawableTypeInfo.hasOwnProperty(type)) {
                const drawableInfo = drawableTypeInfo[type];
                const drawableMap = drawableInfo.drawableMap;
                const drawableList = drawableInfo.drawableList;
                var lenDrawableList = 0;
                for (var id in drawableMap) {
                    if (drawableMap.hasOwnProperty(id)) {
                        drawableList[lenDrawableList++] = drawableMap[id];
                    }
                }
                drawableList.length = lenDrawableList;
                drawableInfo.lenDrawableList = lenDrawableList;
            }
        }
    }

    function sortDrawableList() {
        for (var type in drawableTypeInfo) {
            if (drawableTypeInfo.hasOwnProperty(type)) {
                const drawableInfo = drawableTypeInfo[type];
                if (drawableInfo.isStateSortable) {
                    drawableInfo.drawableList.sort(drawableInfo.stateSortCompare);
                }
            }
        }
    }

    function drawShadowMaps() {
        var lights = scene._lightsState.lights;
        var light;
        var i;
        var len;
        for (i = 0, len = lights.length; i < len; i++) {
            light = lights[i];
            if (!light.castsShadow) {
                continue;
            }
            drawShadowMap(light);
        }
    }

    function drawShadowMap(light) {

        const castsShadow = light.castsShadow;

        if (!castsShadow) {
            return;
        }

        const renderBuf = light.getShadowRenderBuf();

        if (!renderBuf) {
            return;
        }

        renderBuf.bind();

        frameCtx.reset();
        frameCtx.backfaces = true;
        frameCtx.frontface = true;
        frameCtx.drawElements = 0;
        frameCtx.useProgram = -1;
        frameCtx.shadowViewMatrix = light.getShadowViewMatrix();
        frameCtx.shadowProjMatrix = light.getShadowProjMatrix();

        const boundary = scene.viewport.boundary;
        gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

        gl.clearColor(0, 0, 0, 1);
        gl.enable(gl.DEPTH_TEST);
        gl.disable(gl.BLEND);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        let i;
        let drawable;

        for (i = 0; i < drawableListSortedLen; i++) {
            drawable = drawableListSorted[i];
            if (!drawable.visible || !drawable.castsShadow) {
                continue; // For now, culled drawables still cast shadows because they are just out of view
            }
            // if (drawable._material._state.alpha === 0) {
            //     continue;
            // }
            //    drawable.drawShadow(frameCtx, light);
        }

        renderBuf.unbind();
    }

    var draw = (function () { // Draws the drawables in drawableListSorted

        // On the first pass, we'll immediately draw the opaque normal-appearance drawables, while deferring
        // the rest to these bins, then do subsequent passes to render these bins.

        const normalEdgesOpaqueBin = [];
        const normalFillTransparentBin = [];
        const normalEdgesTransparentBin = [];

        const xrayedFillOpaqueBin = [];
        const xrayEdgesOpaqueBin = [];
        const xrayedFillTransparentBin = [];
        const xrayEdgesTransparentBin = [];

        const highlightedFillOpaqueBin = [];
        const highlightedEdgesOpaqueBin = [];
        const highlightedFillTransparentBin = [];
        const highlightedEdgesTransparentBin = [];

        const selectedFillOpaqueBin = [];
        const selectedEdgesOpaqueBin = [];
        const selectedFillTransparentBin = [];
        const selectedEdgesTransparentBin = [];

        const renderFlags = new RenderFlags();

        return function (params) {

            const opaqueOnly = !!params.opaqueOnly;

            if (WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"]) {  // In case context lost/recovered
                gl.getExtension("OES_element_index_uint");
            }

            const ambientColor = scene._lightsState.getAmbientColor();

            frameCtx.reset();
            frameCtx.pass = params.pass;

            const boundary = scene.viewport.boundary;
            gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

            if (canvasTransparent) { // Canvas is transparent
                gl.clearColor(0, 0, 0, 0);
            } else {
                const clearColor = scene.canvas.backgroundColor || ambientColor;
                gl.clearColor(clearColor[0], clearColor[1], clearColor[2], 1.0);
            }

            gl.enable(gl.DEPTH_TEST);
            gl.frontFace(gl.CCW);
            gl.enable(gl.CULL_FACE);
            gl.depthMask(true);
            gl.lineWidth(1);
            frameCtx.lineWidth = 1;

            let i;
            let len;
            let drawable;

            const startTime = Date.now();

            if (bindOutputFrameBuffer) {
                bindOutputFrameBuffer(params.pass);
            }

            if (params.clear !== false) {
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT);
            }

            let normalEdgesOpaqueBinLen = 0;
            let normalFillTransparentBinLen = 0;
            let normalEdgesTransparentBinLen = 0;

            let xrayedFillOpaqueBinLen = 0;
            let xrayEdgesOpaqueBinLen = 0;
            let xrayedFillTransparentBinLen = 0;
            let xrayEdgesTransparentBinLen = 0;

            let highlightedFillOpaqueBinLen = 0;
            let highlightedEdgesOpaqueBinLen = 0;
            let highlightedFillTransparentBinLen = 0;
            let highlightedEdgesTransparentBinLen = 0;

            let selectedFillOpaqueBinLen = 0;
            let selectedEdgesOpaqueBinLen = 0;
            let selectedFillTransparentBinLen = 0;
            let selectedEdgesTransparentBinLen = 0;

            //------------------------------------------------------------------------------------------------------
            // Render normal opaque solids, defer others to bins to render after
            //------------------------------------------------------------------------------------------------------

            for (var type in drawableTypeInfo) {
                if (drawableTypeInfo.hasOwnProperty(type)) {

                    const drawableInfo = drawableTypeInfo[type];
                    const drawableList = drawableInfo.drawableList;

                    for (i = 0, len = drawableList.length; i < len; i++) {

                        drawable = drawableList[i];

                        if (drawable.culled === true || drawable.visible === false) {
                            continue;
                        }

                        drawable.getRenderFlags(renderFlags);

                        if (renderFlags.normalFillOpaque) {
                            drawable.drawNormalFillOpaque(frameCtx);
                        }

                        if (renderFlags.normalEdgesOpaque) {
                            normalEdgesOpaqueBin[normalEdgesOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.normalFillTransparent) {
                            normalFillTransparentBin[normalFillTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.normalEdgesTransparent) {
                            normalEdgesTransparentBin[normalEdgesTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.xrayedFillTransparent) {
                            xrayedFillTransparentBin[xrayedFillTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.xrayedFillOpaque) {
                            xrayedFillOpaqueBin[xrayedFillOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.xrayedEdgesTransparent) {
                            xrayEdgesTransparentBin[xrayEdgesTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.xrayedEdgesOpaque) {
                            xrayEdgesOpaqueBin[xrayEdgesOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.highlightedFillTransparent) {
                            highlightedFillTransparentBin[highlightedFillTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.highlightedFillOpaque) {
                            highlightedFillOpaqueBin[highlightedFillOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.highlightedEdgesTransparent) {
                            highlightedEdgesTransparentBin[highlightedEdgesTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.highlightedEdgesOpaque) {
                            highlightedEdgesOpaqueBin[highlightedEdgesOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.selectedFillTransparent) {
                            selectedFillTransparentBin[selectedFillTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.selectedFillOpaque) {
                            selectedFillOpaqueBin[selectedFillOpaqueBinLen++] = drawable;
                        }

                        if (renderFlags.selectedEdgesTransparent) {
                            selectedEdgesTransparentBin[selectedEdgesTransparentBinLen++] = drawable;
                        }

                        if (renderFlags.selectedEdgesOpaque) {
                            selectedEdgesOpaqueBin[selectedEdgesOpaqueBinLen++] = drawable;
                        }
                    }
                }
            }

            //------------------------------------------------------------------------------------------------------
            // Render deferred bins
            //------------------------------------------------------------------------------------------------------

            if (normalEdgesOpaqueBinLen > 0) {
                for (i = 0; i < normalEdgesOpaqueBinLen; i++) {
                    normalEdgesOpaqueBin[i].drawNormalEdgesOpaque(frameCtx);
                }
            }

            if (xrayedFillOpaqueBinLen > 0) {
                for (i = 0; i < xrayedFillOpaqueBinLen; i++) {
                    xrayedFillOpaqueBin[i].drawXRayedFillOpaque(frameCtx);
                }
            }

            if (xrayEdgesOpaqueBinLen > 0) {
                for (i = 0; i < xrayEdgesOpaqueBinLen; i++) {
                    xrayEdgesOpaqueBin[i].drawXRayedEdgesOpaque(frameCtx);
                }
            }

            const transparentDepthMask = true;
            if (xrayedFillTransparentBinLen > 0 || xrayEdgesTransparentBinLen > 0 || normalFillTransparentBinLen > 0) {
                gl.enable(gl.CULL_FACE);
                gl.enable(gl.BLEND);
                if (blendOneMinusSrcAlpha) { // Makes glTF windows appear correct
                    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                } else {
                    gl.blendEquation(gl.FUNC_ADD);
                    gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                }
                frameCtx.backfaces = false;
                if (!transparentDepthMask) {
                    gl.depthMask(false);
                }
                if (xrayEdgesTransparentBinLen > 0) {
                    for (i = 0; i < xrayEdgesTransparentBinLen; i++) {
                        xrayEdgesTransparentBin[i].drawXRayedEdgesTransparent(frameCtx);
                    }
                }
                if (xrayedFillTransparentBinLen > 0) {
                    for (i = 0; i < xrayedFillTransparentBinLen; i++) {
                        xrayedFillTransparentBin[i].drawXRayedFillTransparent(frameCtx);
                    }
                }
                if (normalFillTransparentBinLen > 0) {
                    for (i = 0; i < normalFillTransparentBinLen; i++) {
                        drawable = normalFillTransparentBin[i];
                        drawable.drawNormalFillTransparent(frameCtx);
                    }
                }
                if (normalEdgesTransparentBinLen > 0) {
                    for (i = 0; i < normalEdgesTransparentBinLen; i++) {
                        drawable = normalEdgesTransparentBin[i];
                        drawable.drawNormalEdgesTransparent(frameCtx);
                    }
                }
                gl.disable(gl.BLEND);
            }

            if (highlightedFillOpaqueBinLen > 0 || highlightedEdgesOpaqueBinLen > 0) {
                frameCtx.lastProgramId = null;
                gl.clear(gl.DEPTH_BUFFER_BIT);
                if (highlightedEdgesOpaqueBinLen > 0) {
                    for (i = 0; i < highlightedEdgesOpaqueBinLen; i++) {
                        highlightedEdgesOpaqueBin[i].drawHighlightedEdgesOpaque(frameCtx);
                    }
                }
                if (highlightedFillOpaqueBinLen > 0) {
                    for (i = 0; i < highlightedFillOpaqueBinLen; i++) {
                        highlightedFillOpaqueBin[i].drawHighlightedFillOpaque(frameCtx);
                    }
                }
            }

            if (highlightedFillTransparentBinLen > 0 || highlightedEdgesTransparentBinLen > 0 || highlightedFillOpaqueBinLen > 0) {
                frameCtx.lastProgramId = null;
                gl.clear(gl.DEPTH_BUFFER_BIT);
                gl.enable(gl.CULL_FACE);
                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                if (highlightedEdgesTransparentBinLen > 0) {
                    for (i = 0; i < highlightedEdgesTransparentBinLen; i++) {
                        highlightedEdgesTransparentBin[i].drawHighlightedEdgesTransparent(frameCtx);
                    }
                }
                if (highlightedFillTransparentBinLen > 0) {
                    for (i = 0; i < highlightedFillTransparentBinLen; i++) {
                        highlightedFillTransparentBin[i].drawHighlightedFillTransparent(frameCtx);
                    }
                }
                gl.disable(gl.BLEND);
            }

            if (selectedFillOpaqueBinLen > 0 || selectedEdgesOpaqueBinLen > 0) {
                frameCtx.lastProgramId = null;
                gl.clear(gl.DEPTH_BUFFER_BIT);
                if (selectedEdgesOpaqueBinLen > 0) {
                    for (i = 0; i < selectedEdgesOpaqueBinLen; i++) {
                        selectedEdgesOpaqueBin[i].drawSelectedEdgesOpaque(frameCtx);
                    }
                }
                if (selectedFillOpaqueBinLen > 0) {
                    for (i = 0; i < selectedFillOpaqueBinLen; i++) {
                        selectedFillOpaqueBin[i].drawSelectedFillOpaque(frameCtx);
                    }
                }
            }

            if (selectedFillTransparentBinLen > 0 || selectedEdgesTransparentBinLen > 0) {
                frameCtx.lastProgramId = null;
                gl.clear(gl.DEPTH_BUFFER_BIT);
                gl.enable(gl.CULL_FACE);
                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                if (selectedEdgesTransparentBinLen > 0) {
                    for (i = 0; i < selectedEdgesTransparentBinLen; i++) {
                        selectedEdgesTransparentBin[i].drawSelectedEdgesTransparent(frameCtx);
                    }
                }
                if (selectedFillTransparentBinLen > 0) {
                    for (i = 0; i < selectedFillTransparentBinLen; i++) {
                        selectedFillTransparentBin[i].drawSelectedFillTransparent(frameCtx);
                    }
                }
                gl.disable(gl.BLEND);
            }

            const endTime = Date.now();
            const frameStats = stats.frame;

            frameStats.renderTime = (endTime - startTime) / 1000.0;
            frameStats.drawElements = frameCtx.drawElements;
            frameStats.drawElements = frameCtx.drawElements;
            frameStats.useProgram = frameCtx.useProgram;
            frameStats.bindTexture = frameCtx.bindTexture;
            frameStats.bindArray = frameCtx.bindArray;

            const numTextureUnits = WEBGL_INFO.MAX_TEXTURE_UNITS;
            for (let ii = 0; ii < numTextureUnits; ii++) {
                gl.activeTexture(gl.TEXTURE0 + ii);
            }
            gl.bindTexture(gl.TEXTURE_CUBE_MAP, null);
            gl.bindTexture(gl.TEXTURE_2D, null);

            const numVertexAttribs = WEBGL_INFO.MAX_VERTEX_ATTRIBS; // Fixes https://github.com/xeokit/xeokit-sdk/issues/174
            for (let ii = 0; ii < numVertexAttribs; ii++) {
                gl.disableVertexAttribArray(ii);
            }

            // Set the backbuffer's alpha to 1.0
            // gl.clearColor(1, 1, 1, 1);
            // gl.colorMask(false, false, false, true);
            // gl.clear(gl.COLOR_BUFFER_BIT);
            // gl.colorMask(true, true, true, true);

            if (unbindOutputFrameBuffer) {
                unbindOutputFrameBuffer(params.pass);
            }
        };
    })();

    /**
     * Picks an Entity.
     * @private
     */
    this.pick = (function () {

        const tempVec3a = math.vec3();
        const tempMat4a = math.mat4();
        const up = math.vec3([0, 1, 0]);
        const pickFrustumMatrix = math.frustumMat4(-1, 1, -1, 1, 0.1, 10000);
        const _pickResult = new PickResult();

        return function (params, pickResult = _pickResult) {

            pickResult.reset();

            updateDrawlist();

            if (WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"]) { // In case context lost/recovered
                gl.getExtension("OES_element_index_uint");
            }

            let canvasX;
            let canvasY;
            let origin;
            let direction;
            let look;
            let pickViewMatrix = null;
            let pickProjMatrix = null;

            pickResult.pickSurface = params.pickSurface;

            if (params.canvasPos) {

                canvasX = params.canvasPos[0];
                canvasY = params.canvasPos[1];

                pickViewMatrix = scene.camera.viewMatrix;
                pickProjMatrix = scene.camera.projMatrix;

                pickResult.canvasPos = params.canvasPos;

            } else {

                // Picking with arbitrary World-space ray
                // Align camera along ray and fire ray through center of canvas

                if (params.matrix) {

                    pickViewMatrix = params.matrix;
                    pickProjMatrix = pickFrustumMatrix;

                } else {

                    origin = params.origin || math.vec3([0, 0, 0]);
                    direction = params.direction || math.vec3([0, 0, 1]);
                    look = math.addVec3(origin, direction, tempVec3a);

                    pickViewMatrix = math.lookAtMat4v(origin, look, up, tempMat4a);
                    pickProjMatrix = pickFrustumMatrix;

                    pickResult.origin = origin;
                    pickResult.direction = direction;
                }

                canvasX = canvas.clientWidth * 0.5;
                canvasY = canvas.clientHeight * 0.5;
            }

            pickBuf = pickBuf || new RenderBuffer(canvas, gl);
            pickBuf.bind();

            const pickable = pickPickable(canvasX, canvasY, pickViewMatrix, pickProjMatrix, params);

            if (!pickable) {
                pickBuf.unbind();
                return null;
            }

            if (params.pickSurface) {

                if (pickable.canPickTriangle && pickable.canPickTriangle()) {
                    pickTriangle(pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult);
                    pickable.pickTriangleSurface(pickViewMatrix, pickProjMatrix, pickResult);

                } else {

                    if (pickable.canPickWorldPos && pickable.canPickWorldPos()) {
                        pickWorldPos(pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult);
                        pickWorldNormal(pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult);
                    }
                }
            }

            pickBuf.unbind();

            pickResult.entity = (pickable.delegatePickedEntity) ? pickable.delegatePickedEntity() : pickable;

            return pickResult;
        };
    })();

    function pickPickable(canvasX, canvasY, pickViewMatrix, pickProjMatrix, params) {

        frameCtx.reset();
        frameCtx.backfaces = true;
        frameCtx.frontface = true; // "ccw"
        frameCtx.pickViewMatrix = pickViewMatrix;
        frameCtx.pickProjMatrix = pickProjMatrix;
        frameCtx.pickInvisible = !!params.pickInvisible;

        const boundary = scene.viewport.boundary;
        gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

        gl.clearColor(0, 0, 0, 0);
        gl.enable(gl.DEPTH_TEST);
        gl.enable(gl.CULL_FACE);
        gl.disable(gl.BLEND);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        let i;
        let len;
        const includeEntityIds = params.includeEntityIds;
        const excludeEntityIds = params.excludeEntityIds;

        for (var type in drawableTypeInfo) {
            if (drawableTypeInfo.hasOwnProperty(type)) {

                const drawableInfo = drawableTypeInfo[type];
                const drawableList = drawableInfo.drawableList;

                for (i = 0, len = drawableList.length; i < len; i++) {

                    const drawable = drawableList[i];

                    if (!drawable.drawPickMesh || drawable.culled === true || (params.pickInvisible !== true && drawable.visible === false) || drawable.pickable === false) {
                        continue;
                    }
                    if (includeEntityIds && !includeEntityIds[drawable.id]) { // TODO: push this logic into drawable
                        continue;
                    }
                    if (excludeEntityIds && excludeEntityIds[drawable.id]) {
                        continue;
                    }

                    drawable.drawPickMesh(frameCtx);
                }
            }
        }

        const pix = pickBuf.read(Math.round(canvasX), Math.round(canvasY));
        let pickID = pix[0] + (pix[1] * 256) + (pix[2] * 256 * 256) + (pix[3] * 256 * 256 * 256);

        if (pickID < 0) {
            return;
        }

        const pickable = pickIDs.items[pickID];

        return pickable;
    }

    function pickTriangle(pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult) {

        if (!pickable.drawPickTriangles) {
            return;
        }

        frameCtx.reset();
        frameCtx.backfaces = true;
        frameCtx.frontface = true; // "ccw"
        frameCtx.pickViewMatrix = pickViewMatrix; // Can be null
        frameCtx.pickProjMatrix = pickProjMatrix; // Can be null
        // frameCtx.pickInvisible = !!params.pickInvisible;

        const boundary = scene.viewport.boundary;
        gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

        gl.clearColor(0, 0, 0, 0);
        gl.enable(gl.DEPTH_TEST);
        gl.enable(gl.CULL_FACE);
        gl.disable(gl.BLEND);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        pickable.drawPickTriangles(frameCtx);

        const pix = pickBuf.read(canvasX, canvasY);

        let primIndex = pix[0] + (pix[1] * 256) + (pix[2] * 256 * 256) + (pix[3] * 256 * 256 * 256);

        primIndex *= 3; // Convert from triangle number to first vertex in indices

        pickResult.primIndex = primIndex;
    }

    var pickWorldPos = (function () {

        const tempVec4a = math.vec4();
        const tempVec4b = math.vec4();
        const tempVec4c = math.vec4();
        const tempVec4d = math.vec4();
        const tempVec4e = math.vec4();
        const tempMat4a = math.mat4();
        const tempMat4b = math.mat4();

        return function (pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult) {

            frameCtx.reset();
            frameCtx.backfaces = true;
            frameCtx.frontface = true; // "ccw"
            frameCtx.pickViewMatrix = pickViewMatrix;
            frameCtx.pickProjMatrix = pickProjMatrix;

            const boundary = scene.viewport.boundary;
            gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

            gl.clearColor(0, 0, 0, 0);
            gl.enable(gl.DEPTH_TEST);
            gl.enable(gl.CULL_FACE);
            gl.disable(gl.BLEND);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

            pickable.drawPickDepths(frameCtx); // Draw color-encoded fragment screen-space depths

            const pix = pickBuf.read(Math.round(canvasX), Math.round(canvasY));

            const screenZ = unpackDepth(pix); // Get screen-space Z at the given canvas coords

            // Calculate clip space coordinates, which will be in range of x=[-1..1] and y=[-1..1], with y=(+1) at top
            var x = (canvasX - canvas.width / 2) / (canvas.width / 2);
            var y = -(canvasY - canvas.height / 2) / (canvas.height / 2);
            var pvMat = math.mulMat4(pickProjMatrix, pickViewMatrix, tempMat4a);
            var pvMatInverse = math.inverseMat4(pvMat, tempMat4b);

            tempVec4a[0] = x;
            tempVec4a[1] = y;
            tempVec4a[2] = -1;
            tempVec4a[3] = 1;

            var world1 = math.transformVec4(pvMatInverse, tempVec4a);
            world1 = math.mulVec4Scalar(world1, 1 / world1[3]);

            tempVec4b[0] = x;
            tempVec4b[1] = y;
            tempVec4b[2] = 1;
            tempVec4b[3] = 1;

            var world2 = math.transformVec4(pvMatInverse, tempVec4b);
            world2 = math.mulVec4Scalar(world2, 1 / world2[3]);

            var dir = math.subVec3(world2, world1, tempVec4c);
            var worldPos = math.addVec3(world1, math.mulVec4Scalar(dir, screenZ, tempVec4d), tempVec4e);

            pickResult.worldPos = worldPos;
        }
    })();

    function unpackDepth(depthZ) {
        var vec = [depthZ[0] / 256.0, depthZ[1] / 256.0, depthZ[2] / 256.0, depthZ[3] / 256.0];
        var bitShift = [1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0];
        return math.dotVec4(vec, bitShift);
    }

    function pickWorldNormal(pickable, canvasX, canvasY, pickViewMatrix, pickProjMatrix, pickResult) {

        frameCtx.reset();
        frameCtx.backfaces = true;
        frameCtx.frontface = true; // "ccw"
        frameCtx.pickViewMatrix = pickViewMatrix;
        frameCtx.pickProjMatrix = pickProjMatrix;

        const boundary = scene.viewport.boundary;
        gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);

        gl.clearColor(0, 0, 0, 0);
        gl.enable(gl.DEPTH_TEST);
        gl.enable(gl.CULL_FACE);
        gl.disable(gl.BLEND);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        pickable.drawPickNormals(frameCtx); // Draw color-encoded fragment World-space normals

        const pix = pickBuf.read(Math.round(canvasX), Math.round(canvasY));

        const worldNormal = [(pix[0] / 256.0) - 0.5, (pix[1] / 256.0) - 0.5, (pix[2] / 256.0) - 0.5];

        math.normalizeVec3(worldNormal);

        pickResult.worldNormal = worldNormal;
    }

    /**
     * Adds a {@link Marker} for occlusion testing.
     * @param marker
     */
    this.addMarker = function (marker) {
        this._occlusionTester = this._occlusionTester || new OcclusionTester(scene);
        this._occlusionTester.addMarker(marker);
    };

    /**
     * Notifies that a {@link Marker#worldPos} has updated.
     * @param marker
     */
    this.markerWorldPosUpdated = function (marker) {
        this._occlusionTester.markerWorldPosUpdated(marker);
    };

    /**
     * Removes a {@link Marker} from occlusion testing.
     * @param marker
     */
    this.removeMarker = function (marker) {
        this._occlusionTester.removeMarker(marker);
    };

    /**
     * Performs an occlusion test for all added {@link Marker}s, updating
     * their {@link Marker#visible} properties accordingly.
     */
    this.doOcclusionTest = function () {

        if (this._occlusionTester) {

            updateDrawlist();

            this._occlusionTester.bindRenderBuf();

            frameCtx.reset();
            frameCtx.backfaces = true;
            frameCtx.frontface = true; // "ccw"

            const boundary = scene.viewport.boundary;

            gl.viewport(boundary[0], boundary[1], boundary[2], boundary[3]);
            gl.clearColor(0, 0, 0, 0);
            gl.enable(gl.DEPTH_TEST);
            gl.enable(gl.CULL_FACE);
            gl.disable(gl.BLEND);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

            for (var type in drawableTypeInfo) {
                if (drawableTypeInfo.hasOwnProperty(type)) {
                    const drawableInfo = drawableTypeInfo[type];
                    const drawableList = drawableInfo.drawableList;
                    for (var i = 0, len = drawableList.length; i < len; i++) {
                        const drawable = drawableList[i];
                        if (!drawable.drawOcclusion || drawable.culled === true || drawable.visible === false || drawable.pickable === false) {

                            // nTODO: Exclude transpArent
                            continue;
                        }
                        drawable.drawOcclusion(frameCtx);
                    }
                }
            }

            this._occlusionTester.drawMarkers(frameCtx);
            this._occlusionTester.doOcclusionTest(); // Updates Marker "visible" properties
            this._occlusionTester.unbindRenderBuf();
        }
    };

    /**
     * Read pixels from the renderer's frameCtx buffer. Performs a force-render first
     * @param pixels
     * @param colors
     * @param len
     * @param opaqueOnly
     * @private
     */
    this.readPixels = function (pixels, colors, len, opaqueOnly) {
        readPixelBuf = readPixelBuf || (readPixelBuf = new RenderBuffer(canvas, gl));
        readPixelBuf.bind();
        readPixelBuf.clear();
        this.render({force: true, opaqueOnly: opaqueOnly});
        let color;
        let i;
        let j;
        let k;
        for (i = 0; i < len; i++) {
            j = i * 2;
            k = i * 4;
            color = readPixelBuf.read(pixels[j], pixels[j + 1]);
            colors[k] = color[0];
            colors[k + 1] = color[1];
            colors[k + 2] = color[2];
            colors[k + 3] = color[3];
        }
        readPixelBuf.unbind();
        imageDirty = true;
    };

    /**
     * Destroys this renderer.
     * @private
     */
    this.destroy = function () {
        drawableTypeInfo = {};
        drawables = {};
        if (pickBuf) {
            pickBuf.destroy();
        }
        if (readPixelBuf) {
            readPixelBuf.destroy();
        }
        if (this._occlusionTester) {
            this._occlusionTester.destroy();
        }
    };
};

export {Renderer};