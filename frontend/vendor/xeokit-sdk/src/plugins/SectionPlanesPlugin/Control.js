import {math} from "../../viewer/scene/math/math.js";

import {buildCylinderGeometry} from "../../viewer/scene/geometry/builders/buildCylinderGeometry.js";
import {buildTorusGeometry} from "../../viewer/scene/geometry/builders/buildTorusGeometry.js";
import {buildBoxGeometry} from "../../viewer/scene/geometry/builders/buildBoxGeometry.js";

import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {EmphasisMaterial} from "../../viewer/scene/materials/EmphasisMaterial.js";
import {Node} from "../../viewer/scene/nodes/Node.js";
import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {buildSphereGeometry} from "../../viewer/scene/geometry/builders/buildSphereGeometry.js";

const zeroVec = new Float32Array([0, 0, 1]);
const quat = new Float32Array(4);

/**
 * Controls a {@link SectionPlane} with mouse and touch input.
 *
 * @private
 */
class Control {

    /** @private */
    constructor(plugin) {

        /**
         * ID of this Control.
         *
         * SectionPlaneControls are mapped by this ID in {@link SectionPlanesPlugin#sectionPlaneControls}.
         *
         * @property id
         * @type {String|Number}
         */
        this.id = null;

        this._viewer = plugin.viewer;

        this._visible = false;
        this._pos = math.vec3(); // Holds the current position of the center of the clip plane.
        this._baseDir = math.vec3(); // Saves direction of clip plane when we start dragging an arrow or ring.
        this._rootNode = null; // Root of Node graph that represents this control in the 3D scene
        this._displayMeshes = null; // Meshes that are always visible
        this._affordanceMeshes = null; // Meshes displayed momentarily for affordance

        this._createNodes();
        this._bindEvents();
    }

    /**
     * Called by SectionPlanesPlugin to assign this Control to a SectionPlane.
     * SectionPlanesPlugin keeps SectionPlaneControls in a reuse pool.
     * @private
     */
    _setSectionPlane(sectionPlane) {
        this._sectionPlane = sectionPlane;
        if (sectionPlane) {
            this.id = sectionPlane.id;
            this._setPos(sectionPlane.pos);
            this._setDir(sectionPlane.dir);
        }
    }

    /**
     * Gets the {@link SectionPlane} controlled by this Control.
     * @returns {SectionPlane} The SectionPlane.
     */
    get sectionPlane() {
        return this._sectionPlane;
    }

    /** @private */
    _setPos(xyz) {
        this._pos.set(xyz);
        this._rootNode.position = xyz;
    }

    /** @private */
    _setDir(xyz) {
        this._baseDir.set(xyz);
        this._rootNode.quaternion = math.vec3PairToQuaternion(zeroVec, xyz, quat);
    }

    /**
     * Sets if this Control is visible.
     *
     * @type {Boolean}
     */
    setVisible(visible = true) {
        if (this._visible === visible) {
            return;
        }
        this._visible = visible;
        var id;
        for (id in this._displayMeshes) {
            if (this._displayMeshes.hasOwnProperty(id)) {
                this._displayMeshes[id].visible = visible;
            }
        }
        if (!visible) {
            for (id in this._affordanceMeshes) {
                if (this._affordanceMeshes.hasOwnProperty(id)) {
                    this._affordanceMeshes[id].visible = visible;
                }
            }
        }
    }

    /**
     * Gets if this Control is visible.
     *
     * @type {Boolean}
     */
    getVisible() {
        return this._visible;
    }

    /**
     * Sets if this Control is culled. This is called by SectionPlanesPlugin to
     * temporarily hide the Control while a snapshot is being taken by Viewer#getSnapshot().
     * @param culled
     */
    setCulled(culled) {
        var id;
        for (id in this._displayMeshes) {
            if (this._displayMeshes.hasOwnProperty(id)) {
                this._displayMeshes[id].culled = culled;
            }
        }
        if (!culled) {
            for (id in this._affordanceMeshes) {
                if (this._affordanceMeshes.hasOwnProperty(id)) {
                    this._affordanceMeshes[id].culled = culled;
                }
            }
        }
    }

    /**
     * Builds the Entities that represent this Control.
     * @private
     */
    _createNodes() {

        const NO_STATE_INHERIT = false;
        const scene = this._viewer.scene;
        const radius = 1.0;
        const handleTubeRadius = 0.06;
        const hoopRadius = radius - 0.2;
        const tubeRadius = 0.01;
        const arrowRadius = 0.07;

        this._rootNode = new Node(scene, {
            position: [0, 0, 0],
            scale: [5, 5, 5]
        });

        const rootNode = this._rootNode;

        const shapes = {// Reusable geometries

            arrowHead: new ReadableGeometry(rootNode, buildCylinderGeometry({
                radiusTop: 0.001,
                radiusBottom: arrowRadius,
                radialSegments: 32,
                heightSegments: 1,
                height: 0.2,
                openEnded: false
            })),

            arrowHeadBig: new ReadableGeometry(rootNode, buildCylinderGeometry({
                radiusTop: 0.001,
                radiusBottom: 0.09,
                radialSegments: 32,
                heightSegments: 1,
                height: 0.25,
                openEnded: false
            })),

            arrowHeadHandle: new ReadableGeometry(rootNode, buildCylinderGeometry({
                radiusTop: 0.09,
                radiusBottom: 0.09,
                radialSegments: 8,
                heightSegments: 1,
                height: 0.37,
                openEnded: false
            })),

            curve: new ReadableGeometry(rootNode, buildTorusGeometry({
                radius: hoopRadius,
                tube: tubeRadius,
                radialSegments: 64,
                tubeSegments: 14,
                arc: (Math.PI * 2.0) / 4.0
            })),

            curveHandle: new ReadableGeometry(rootNode, buildTorusGeometry({
                radius: hoopRadius,
                tube: handleTubeRadius,
                radialSegments: 64,
                tubeSegments: 14,
                arc: (Math.PI * 2.0) / 4.0
            })),

            hoop: new ReadableGeometry(rootNode, buildTorusGeometry({
                radius: hoopRadius,
                tube: tubeRadius,
                radialSegments: 64,
                tubeSegments: 8,
                arc: (Math.PI * 2.0)
            })),

            axis: new ReadableGeometry(rootNode, buildCylinderGeometry({
                radiusTop: tubeRadius,
                radiusBottom: tubeRadius,
                radialSegments: 20,
                heightSegments: 1,
                height: radius,
                openEnded: false
            })),

            axisHandle: new ReadableGeometry(rootNode, buildCylinderGeometry({
                radiusTop: 0.08,
                radiusBottom: 0.08,
                radialSegments: 20,
                heightSegments: 1,
                height: radius,
                openEnded: false
            }))
        };

        const materials = { // Reusable materials

            pickable: new PhongMaterial(rootNode, { // Invisible material for pickable handles, which define a pickable 3D area
                diffuse: [1, 1, 0],
                alpha: 0, // Invisible
                alphaMode: "blend"
            }),

            red: new PhongMaterial(rootNode, {
                diffuse: [1, 0.0, 0.0],
                emissive: [1, 0.0, 0.0],
                ambient: [0.0, 0.0, 0.0],
                specular: [.6, .6, .3],
                shininess: 80,
                lineWidth: 2
            }),

            highlightRed: new EmphasisMaterial(rootNode, { // Emphasis for red rotation affordance hoop
                edges: false,
                fill: true,
                fillColor: [1, 0, 0],
                fillAlpha: 0.6
            }),

            green: new PhongMaterial(rootNode, {
                diffuse: [0.0, 1, 0.0],
                emissive: [0.0, 1, 0.0],
                ambient: [0.0, 0.0, 0.0],
                specular: [.6, .6, .3],
                shininess: 80,
                lineWidth: 2
            }),

            highlightGreen: new EmphasisMaterial(rootNode, { // Emphasis for green rotation affordance hoop
                edges: false,
                fill: true,
                fillColor: [0, 1, 0],
                fillAlpha: 0.6
            }),

            blue: new PhongMaterial(rootNode, {
                diffuse: [0.0, 0.0, 1],
                emissive: [0.0, 0.0, 1],
                ambient: [0.0, 0.0, 0.0],
                specular: [.6, .6, .3],
                shininess: 80,
                lineWidth: 2
            }),

            highlightBlue: new EmphasisMaterial(rootNode, { // Emphasis for blue rotation affordance hoop
                edges: false,
                fill: true,
                fillColor: [0, 0, 1],
                fillAlpha: 0.2
            }),

            center: new PhongMaterial(rootNode, {
                diffuse: [0.0, 0.0, 0.0],
                emissive: [0, 0, 0],
                ambient: [0.0, 0.0, 0.0],
                specular: [.6, .6, .3],
                shininess: 80
            }),

            highlightBall: new EmphasisMaterial(rootNode, {
                edges: false,
                fill: true,
                fillColor: [0.5, 0.5, 0.5],
                fillAlpha: 0.5,
                vertices: false
            }),

            highlightPlane: new EmphasisMaterial(rootNode, {
                edges: true,
                edgeWidth: 3,
                fill: false,
                fillColor: [0.5, 0.5, .5],
                fillAlpha: 0.5,
                vertices: false
            })
        };

        this._displayMeshes = {

            plane: rootNode.addChild(new Mesh(rootNode, {
                geometry: new ReadableGeometry(rootNode, {
                    primitive: "triangles",
                    positions: [
                        0.5, 0.5, 0.0, 0.5, -0.5, 0.0, // 0
                        -0.5, -0.5, 0.0, -0.5, 0.5, 0.0, // 1
                        0.5, 0.5, -0.0, 0.5, -0.5, -0.0, // 2
                        -0.5, -0.5, -0.0, -0.5, 0.5, -0.0 // 3
                    ],
                    indices: [0, 1, 2, 2, 3, 0]
                }),
                material: new PhongMaterial(rootNode, {
                    emissive: [0, 0.0, 0],
                    diffuse: [0, 0, 0],
                    backfaces: true
                }),
                opacity: 0.6,
                ghosted: true,
                ghostMaterial: new EmphasisMaterial(rootNode, {
                    edges: false,
                    filled: true,
                    fillColor: [1, 1, 0],
                    edgeColor: [0, 0, 0],
                    fillAlpha: 0.1,
                    backfaces: true
                }),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false,
                scale: [2.4, 2.4, 1]
            }), NO_STATE_INHERIT),

            planeFrame: rootNode.addChild(new Mesh(rootNode, { // Visible frame
                geometry: new ReadableGeometry(rootNode, buildTorusGeometry({
                    center: [0, 0, 0],
                    radius: 1.7,
                    tube: tubeRadius * 2,
                    radialSegments: 4,
                    tubeSegments: 4,
                    arc: Math.PI * 2.0
                })),
                material: new PhongMaterial(rootNode, {
                    emissive: [0, 0, 0],
                    diffuse: [0, 0, 0],
                    specular: [0, 0, 0],
                    shininess: 0
                }),
                //highlighted: true,
                highlightMaterial: new EmphasisMaterial(rootNode, {
                    edges: false,
                    edgeColor: [0.0, 0.0, 0.0],
                    filled: true,
                    fillColor: [0.8, 0.8, 0.8],
                    fillAlpha: 1.0
                }),
                pickable: false,
                collidable: false,
                clippable: false,
                visible: false,
                scale: [1, 1, .1],
                rotation: [0, 0, 45]
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            xCurve: rootNode.addChild(new Mesh(rootNode, { // Red hoop about Y-axis
                geometry: shapes.curve,
                material: materials.red,
                matrix: (function () {
                    const rotate2 = math.rotationMat4v(90 * math.DEGTORAD, [0, 1, 0], math.identityMat4());
                    const rotate1 = math.rotationMat4v(270 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate1, rotate2, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                backfaces: true,
                visible: false
            }), NO_STATE_INHERIT),

            xCurveHandle: rootNode.addChild(new Mesh(rootNode, { // Red hoop about Y-axis
                geometry: shapes.curveHandle,
                material: materials.pickable,
                matrix: (function () {
                    const rotate2 = math.rotationMat4v(90 * math.DEGTORAD, [0, 1, 0], math.identityMat4());
                    const rotate1 = math.rotationMat4v(270 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate1, rotate2, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                backfaces: true,
                visible: false
            }), NO_STATE_INHERIT),

            xCurveArrow1: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.red,
                matrix: (function () {
                    const translate = math.translateMat4c(0., -0.07, -0.8, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    const rotate = math.rotationMat4v(0 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(math.mulMat4(translate, scale, math.identityMat4()), rotate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            xCurveArrow2: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.red,
                matrix: (function () {
                    const translate = math.translateMat4c(0.0, -0.8, -0.07, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    const rotate = math.rotationMat4v(90 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(math.mulMat4(translate, scale, math.identityMat4()), rotate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            yCurve: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.curve,
                material: materials.green,
                rotation: [-90, 0, 0],
                pickable: false,
                collidable: true,
                clippable: false,
                backfaces: true,
                visible: false
            }), NO_STATE_INHERIT),

            yCurveHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.curveHandle,
                material: materials.pickable,
                rotation: [-90, 0, 0],
                pickable: true,
                collidable: true,
                clippable: false,
                backfaces: true,
                visible: false
            }), NO_STATE_INHERIT),

            yCurveArrow1: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.green,
                matrix: (function () {
                    const translate = math.translateMat4c(0.07, 0, -0.8, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    const rotate = math.rotationMat4v(90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(math.mulMat4(translate, scale, math.identityMat4()), rotate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            yCurveArrow2: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.green,
                matrix: (function () {
                    const translate = math.translateMat4c(0.8, 0.0, -0.07, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    const rotate = math.rotationMat4v(90 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(math.mulMat4(translate, scale, math.identityMat4()), rotate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            zCurve: rootNode.addChild(new Mesh(rootNode, { // Blue hoop about Z-axis
                geometry: shapes.curve,
                material: materials.blue,
                matrix: math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4()),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zCurveHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.curveHandle,
                material: materials.pickable,
                matrix: math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4()),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zCurveCurveArrow1: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.blue,
                matrix: (function () {
                    const translate = math.translateMat4c(.8, -0.07, 0, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    return math.mulMat4(translate, scale, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zCurveArrow2: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.blue,
                matrix: (function () {
                    const translate = math.translateMat4c(.05, -0.8, 0, math.identityMat4());
                    const scale = math.scaleMat4v([0.6, 0.6, 0.6], math.identityMat4());
                    const rotate = math.rotationMat4v(90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(math.mulMat4(translate, scale, math.identityMat4()), rotate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            center: rootNode.addChild(new Mesh(rootNode, {
                geometry: new ReadableGeometry(rootNode, buildSphereGeometry({
                    radius: 0.05
                })),
                material: materials.center,
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            xAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.red,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            xAxisArrowHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadHandle,
                material: materials.pickable,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            xAxis: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axis,
                material: materials.red,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius / 2, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            xAxisHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axisHandle,
                material: materials.pickable,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius / 2, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            yAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.green,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            yAxisArrowHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadHandle,
                material: materials.pickable,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false,
                opacity: 0.2
            }), NO_STATE_INHERIT),

            yShaft: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axis,
                material: materials.green,
                position: [0, -radius / 2, 0],
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            yShaftHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axisHandle,
                material: materials.pickable,
                position: [0, -radius / 2, 0],
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            //----------------------------------------------------------------------------------------------------------
            //
            //----------------------------------------------------------------------------------------------------------

            zAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHead,
                material: materials.blue,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0.8, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zAxisArrowHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadHandle,
                material: materials.pickable,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0.8, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: true,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),


            zShaft: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axis,
                material: materials.blue,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius / 2, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                clippable: false,
                pickable: false,
                collidable: true,
                visible: false
            }), NO_STATE_INHERIT),

            zAxisHandle: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.axisHandle,
                material: materials.pickable,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius / 2, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                clippable: false,
                pickable: true,
                collidable: true,
                visible: false
            }), NO_STATE_INHERIT)
        };

        this._affordanceMeshes = {

            planeFrame: rootNode.addChild(new Mesh(rootNode, {
                geometry: new ReadableGeometry(rootNode, buildTorusGeometry({
                    center: [0, 0, 0],
                    radius: 2,
                    tube: tubeRadius,
                    radialSegments: 4,
                    tubeSegments: 4,
                    arc: Math.PI * 2.0
                })),
                material: new PhongMaterial(rootNode, {
                    ambient: [1, 1, 1],
                    diffuse: [0, 0, 0],
                    emissive: [1, 1, 0]
                }),
                highlighted: true,
                highlightMaterial: new EmphasisMaterial(rootNode, {
                    edges: false,
                    filled: true,
                    fillColor: [1, 1, 0],
                    fillAlpha: 1.0
                }),
                pickable: false,
                collidable: false,
                clippable: false,
                visible: false,
                scale: [1, 1, 1],
                rotation: [0, 0, 45]
            }), NO_STATE_INHERIT),

            xHoop: rootNode.addChild(new Mesh(rootNode, { // Full 
                geometry: shapes.hoop,
                material: materials.red,
                highlighted: true,
                highlightMaterial: materials.highlightRed,
                matrix: (function () {
                    const rotate2 = math.rotationMat4v(90 * math.DEGTORAD, [0, 1, 0], math.identityMat4());
                    const rotate1 = math.rotationMat4v(270 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate1, rotate2, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            yHoop: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.hoop,
                material: materials.green,
                highlighted: true,
                highlightMaterial: materials.highlightGreen,
                rotation: [-90, 0, 0],
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zHoop: rootNode.addChild(new Mesh(rootNode, { // Blue hoop about Z-axis
                geometry: shapes.hoop,
                material: materials.blue,
                highlighted: true,
                highlightMaterial: materials.highlightBlue,
                matrix: math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4()),
                pickable: false,
                collidable: true,
                clippable: false,
                backfaces: true,
                visible: false
            }), NO_STATE_INHERIT),

            xAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadBig,
                material: materials.red,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0, 0, 1], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            yAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadBig,
                material: materials.green,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(180 * math.DEGTORAD, [1, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT),

            zAxisArrow: rootNode.addChild(new Mesh(rootNode, {
                geometry: shapes.arrowHeadBig,
                material: materials.blue,
                matrix: (function () {
                    const translate = math.translateMat4c(0, radius + .1, 0, math.identityMat4());
                    const rotate = math.rotationMat4v(-90 * math.DEGTORAD, [0.8, 0, 0], math.identityMat4());
                    return math.mulMat4(rotate, translate, math.identityMat4());
                })(),
                pickable: false,
                collidable: true,
                clippable: false,
                visible: false
            }), NO_STATE_INHERIT)
        };
    }

    _bindEvents() {

        const self = this;

        var grabbed = false;

        const DRAG_ACTIONS = {
            none: -1,
            xTranslate: 0,
            yTranslate: 1,
            zTranslate: 2,
            xRotate: 3,
            yRotate: 4,
            zRotate: 5
        };

        const rootNode = this._rootNode;

        var nextDragAction = null; // As we hover grabbed an arrow or hoop, self is the action we would do if we then dragged it.
        var dragAction = null; // Action we're doing while we drag an arrow or hoop.
        const lastCanvasPos = math.vec2();

        const xBaseAxis = math.vec3([1, 0, 0]);
        const yBaseAxis = math.vec3([0, 1, 0]);
        const zBaseAxis = math.vec3([0, 0, 1]);

        const canvas = this._viewer.scene.canvas.canvas;
        const camera = this._viewer.camera;
        const scene = this._viewer.scene;

        canvas.oncontextmenu = function (e) {
            e.preventDefault();
        };

        { // Keep gizmo screen size constant
            const tempVec3a = math.vec3([0, 0, 0]);
            var distDirty = true;
            var lastDist = -1;
            this._onCameraViewMatrix = scene.camera.on("viewMatrix", () => {
                distDirty = true;
            });
            this._onCameraProjMatrix = scene.camera.on("projMatrix", () => {
                distDirty = true;
            });
            this._onSceneTick = scene.on("tick", () => {
                var dist = Math.abs(math.lenVec3(math.subVec3(scene.camera.eye, rootNode.position, tempVec3a)));
                if (dist !== lastDist) {
                    var scale = 10 * (dist / 50);
                    rootNode.scale = [scale, scale, scale];
                    lastDist = dist;
                }
            });
        }

        const getClickCoordsWithinElement = (function () {
            const canvasPos = new Float32Array(2);
            return function (event) {
                if (!event) {
                    event = window.event;
                    canvasPos[0] = event.x;
                    canvasPos[1] = event.y;
                } else {
                    var element = event.target;
                    var totalOffsetLeft = 0;
                    var totalOffsetTop = 0;

                    while (element.offsetParent) {
                        totalOffsetLeft += element.offsetLeft;
                        totalOffsetTop += element.offsetTop;
                        element = element.offsetParent;
                    }
                    canvasPos[0] = event.pageX - totalOffsetLeft;
                    canvasPos[1] = event.pageY - totalOffsetTop;
                }
                return canvasPos;
            };
        })();

        const localToWorldVec = (function () {
            const mat = math.mat4();
            return function (localVec, worldVec) {
                math.quaternionToMat4(self._rootNode.quaternion, mat);
                math.transformVec3(mat, localVec, worldVec);
                math.normalizeVec3(worldVec);
                return worldVec;
            };
        })();

        var getTranslationPlane = (function () {
            const planeNormal = math.vec3();
            return function (worldAxis) {
                const absX = Math.abs(worldAxis[0]);
                if (absX > Math.abs(worldAxis[1]) && absX > Math.abs(worldAxis[2])) {
                    math.cross3Vec3(worldAxis, [0, 1, 0], planeNormal);
                } else {
                    math.cross3Vec3(worldAxis, [1, 0, 0], planeNormal);
                }
                math.cross3Vec3(planeNormal, worldAxis, planeNormal);
                math.normalizeVec3(planeNormal);
                return planeNormal;
            }
        })();

        const dragTranslateSectionPlane = (function () {
            const p1 = math.vec3();
            const p2 = math.vec3();
            const worldAxis = math.vec4();
            return function (baseAxis, fromMouse, toMouse) {
                localToWorldVec(baseAxis, worldAxis);
                const planeNormal = getTranslationPlane(worldAxis, fromMouse, toMouse);
                getPointerPlaneIntersect(fromMouse, planeNormal, p1);
                getPointerPlaneIntersect(toMouse, planeNormal, p2);
                math.subVec3(p2, p1);
                const dot = math.dotVec3(p2, worldAxis);
                self._pos[0] += worldAxis[0] * dot;
                self._pos[1] += worldAxis[1] * dot;
                self._pos[2] += worldAxis[2] * dot;
                self._rootNode.position = self._pos;
                if (self.sectionPlane) {
                    self.sectionPlane.pos = self._pos;
                }
            }
        })();

        var dragRotateSectionPlane = (function () {
            const p1 = math.vec4();
            const p2 = math.vec4();
            const c = math.vec4();
            const worldAxis = math.vec4();
            return function (baseAxis, fromMouse, toMouse) {
                localToWorldVec(baseAxis, worldAxis);
                const hasData = getPointerPlaneIntersect(fromMouse, worldAxis, p1) && getPointerPlaneIntersect(toMouse, worldAxis, p2);
                if (!hasData) { // Find intersections with view plane and project down to origin
                    const planeNormal = getTranslationPlane(worldAxis, fromMouse, toMouse);
                    getPointerPlaneIntersect(fromMouse, planeNormal, p1, 1); // Ensure plane moves closer to camera so angles become workable
                    getPointerPlaneIntersect(toMouse, planeNormal, p2, 1);
                    var dot = math.dotVec3(p1, worldAxis);
                    p1[0] -= dot * worldAxis[0];
                    p1[1] -= dot * worldAxis[1];
                    p1[2] -= dot * worldAxis[2];
                    dot = math.dotVec3(p2, worldAxis);
                    p2[0] -= dot * worldAxis[0];
                    p2[1] -= dot * worldAxis[1];
                    p2[2] -= dot * worldAxis[2];
                }
                math.normalizeVec3(p1);
                math.normalizeVec3(p2);
                dot = math.dotVec3(p1, p2);
                dot = math.clamp(dot, -1.0, 1.0); // Rounding errors cause dot to exceed allowed range
                var incDegrees = Math.acos(dot) * math.RADTODEG;
                math.cross3Vec3(p1, p2, c);
                if (math.dotVec3(c, worldAxis) < 0.0) {
                    incDegrees = -incDegrees;
                }
                self._rootNode.rotate(baseAxis, incDegrees);
                rotateSectionPlane();
            }
        })();

        var getPointerPlaneIntersect = (function () {
            const dir = math.vec4([0, 0, 0, 1]);
            const matrix = math.mat4();
            return function (mouse, axis, dest, offset) {
                offset = offset || 0;
                dir[0] = mouse[0] / canvas.width * 2.0 - 1.0;
                dir[1] = -(mouse[1] / canvas.height * 2.0 - 1.0);
                dir[2] = 0.0;
                dir[3] = 1.0;
                math.mulMat4(camera.projMatrix, camera.viewMatrix, matrix); // Unproject norm device coords to view coords
                math.inverseMat4(matrix);
                math.transformVec4(matrix, dir, dir);
                math.mulVec4Scalar(dir, 1.0 / dir[3]); // This is now point A on the ray in world space
                var rayO = camera.eye; // The direction
                math.subVec4(dir, rayO, dir);
                const origin = self._sectionPlane.pos; // Plane origin:
                var d = -math.dotVec3(origin, axis) - offset;
                var dot = math.dotVec3(axis, dir);
                if (Math.abs(dot) > 0.005) {
                    var t = -(math.dotVec3(axis, rayO) + d) / dot;
                    math.mulVec3Scalar(dir, t, dest);
                    math.addVec3(dest, rayO);
                    math.subVec3(dest, origin, dest);
                    return true;
                }
                return false;
            }
        })();

        const rotateSectionPlane = (function () {
            const dir = math.vec3();
            const mat = math.mat4();
            return function () {
                if (self.sectionPlane) {
                    math.quaternionToMat4(rootNode.quaternion, mat);  // << ---
                    math.transformVec3(mat, [0, 0, 1], dir);
                    self._sectionPlane.dir = dir;
                }
            };
        })();

        {
            var mouseDownLeft;
            var mouseDownMiddle;
            var mouseDownRight;
            var down = false;
            var lastAffordanceMesh;

            this._onCameraControlHover = this._viewer.cameraControl.on("hoverEnter", (hit) => {
                if (!this._visible) {
                    return;
                }
                if (down) {
                    return;
                }
                grabbed = false;
                if (lastAffordanceMesh) {
                    lastAffordanceMesh.visible = false;
                }
                var affordanceMesh;
                const meshId = hit.entity.id;
                switch (meshId) {

                    case this._displayMeshes.xAxisArrowHandle.id:
                        affordanceMesh = this._affordanceMeshes.xAxisArrow;
                        nextDragAction = DRAG_ACTIONS.xTranslate;
                        break;

                    case this._displayMeshes.xAxisHandle.id:
                        affordanceMesh = this._affordanceMeshes.xAxisArrow;
                        nextDragAction = DRAG_ACTIONS.xTranslate;
                        break;

                    case this._displayMeshes.yAxisArrowHandle.id:
                        affordanceMesh = this._affordanceMeshes.yAxisArrow;
                        nextDragAction = DRAG_ACTIONS.yTranslate;
                        break;

                    case this._displayMeshes.yShaftHandle.id:
                        affordanceMesh = this._affordanceMeshes.yAxisArrow;
                        nextDragAction = DRAG_ACTIONS.yTranslate;
                        break;

                    case this._displayMeshes.zAxisArrowHandle.id:
                        affordanceMesh = this._affordanceMeshes.zAxisArrow;
                        nextDragAction = DRAG_ACTIONS.zTranslate;
                        break;

                    case this._displayMeshes.zAxisHandle.id:
                        affordanceMesh = this._affordanceMeshes.zAxisArrow;
                        nextDragAction = DRAG_ACTIONS.zTranslate;
                        break;

                    case this._displayMeshes.xCurveHandle.id:
                        affordanceMesh = this._affordanceMeshes.xHoop;
                        nextDragAction = DRAG_ACTIONS.xRotate;
                        break;

                    case this._displayMeshes.yCurveHandle.id:
                        affordanceMesh = this._affordanceMeshes.yHoop;
                        nextDragAction = DRAG_ACTIONS.yRotate;
                        break;

                    case this._displayMeshes.zCurveHandle.id:
                        affordanceMesh = this._affordanceMeshes.zHoop;
                        nextDragAction = DRAG_ACTIONS.zRotate;
                        break;

                    default:
                        nextDragAction = DRAG_ACTIONS.none;
                        return; // Not clicked an arrow or hoop
                }
                if (affordanceMesh) {
                    affordanceMesh.visible = true;
                }
                lastAffordanceMesh = affordanceMesh;
                grabbed = true;
            });

            this._onCameraControlHoverLeave = this._viewer.cameraControl.on("hoverOut", (hit) => {
                if (!this._visible) {
                    return;
                }
                if (lastAffordanceMesh) {
                    lastAffordanceMesh.visible = false;
                }
                lastAffordanceMesh = null;
                nextDragAction = DRAG_ACTIONS.none;
            });

            canvas.addEventListener("mousedown", this._canvasMouseDownListener = (e) => {
                e.preventDefault();
                if (!this._visible) {
                    return;
                }
                if (!grabbed) {
                    return;
                }
                this._viewer.cameraControl.pointerEnabled = false;
                switch (e.which) {
                    case 1: // Left button
                        mouseDownLeft = true;
                        down = true;
                        var canvasPos = getClickCoordsWithinElement(e);
                        dragAction = nextDragAction;
                        lastCanvasPos[0] = canvasPos[0];
                        lastCanvasPos[1] = canvasPos[1];
                        break;

                    default:
                        break;
                }
            });

            canvas.addEventListener("mousemove", this._canvasMouseMoveListener = (e) => {
                if (!this._visible) {
                    return;
                }
                if (!down) {
                    return;
                }
                var canvasPos = getClickCoordsWithinElement(e);
                const x = canvasPos[0];
                const y = canvasPos[1];

                switch (dragAction) {
                    case DRAG_ACTIONS.xTranslate:
                        dragTranslateSectionPlane(xBaseAxis, lastCanvasPos, canvasPos);
                        break;
                    case DRAG_ACTIONS.yTranslate:
                        dragTranslateSectionPlane(yBaseAxis, lastCanvasPos, canvasPos);
                        break;
                    case DRAG_ACTIONS.zTranslate:
                        dragTranslateSectionPlane(zBaseAxis, lastCanvasPos, canvasPos);
                        break;
                    case DRAG_ACTIONS.xRotate:
                        dragRotateSectionPlane(xBaseAxis, lastCanvasPos, canvasPos);
                        break;
                    case DRAG_ACTIONS.yRotate:
                        dragRotateSectionPlane(yBaseAxis, lastCanvasPos, canvasPos);
                        break;
                    case DRAG_ACTIONS.zRotate:
                        dragRotateSectionPlane(zBaseAxis, lastCanvasPos, canvasPos);
                        break;
                }

                lastCanvasPos[0] = x;
                lastCanvasPos[1] = y;
            });

            canvas.addEventListener("mouseup", this._canvasMouseUpListener = (e) => {
                if (!this._visible) {
                    return;
                }
                this._viewer.cameraControl.pointerEnabled = true;
                if (!down) {
                    return;
                }
                switch (e.which) {
                    case 1: // Left button
                        mouseDownLeft = false;
                        break;
                    case 2: // Middle/both buttons
                        mouseDownMiddle = false;
                        break;
                    case 3: // Right button
                        mouseDownRight = false;
                        break;
                    default:
                        break;
                }
                down = false;
                grabbed = false;
            });

            canvas.addEventListener("wheel", this._canvasWheelListener = (e) => {
                if (!this._visible) {
                    return;
                }
                var delta = Math.max(-1, Math.min(1, -e.deltaY * 40));
                if (delta === 0) {
                    return;
                }
            });
        }
    }

    _destroy() {
        this._unbindEvents();
        this._destroyNodes();
    }

    _unbindEvents() {

        const viewer = this._viewer;
        const scene = viewer.scene;
        const canvas = scene.canvas.canvas;
        const camera = viewer.camera;
        const cameraControl = viewer.cameraControl;

        scene.off(this._onSceneTick);

        canvas.removeEventListener("mousedown", this._canvasMouseDownListener);
        canvas.removeEventListener("mousemove", this._canvasMouseMoveListener);
        canvas.removeEventListener("mouseup", this._canvasMouseUpListener);
        canvas.removeEventListener("mouseenter", this._canvasMouseEnterListener);
        canvas.removeEventListener("mouseleave", this._canvasMouseLeaveListener);
        canvas.removeEventListener("wheel", this._canvasWheelListener);

        camera.off(this._onCameraViewMatrix);
        camera.off(this._onCameraProjMatrix);

        cameraControl.off(this._onCameraControlHover);
        cameraControl.off(this._onCameraControlHoverLeave);
    }

    _destroyNodes() {
        this._rootNode.destroy();
        this._displayMeshes = {};
        this._affordanceMeshes = {};
    }
}

export {Control};