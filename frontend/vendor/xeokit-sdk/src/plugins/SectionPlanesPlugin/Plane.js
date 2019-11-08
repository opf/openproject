import {math} from "../../viewer/scene/math/math.js";
import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {buildBoxGeometry} from "../../viewer/scene/geometry/builders/buildBoxGeometry.js";
import {EdgeMaterial} from "../../viewer/scene/materials/EdgeMaterial.js";
import {EmphasisMaterial} from "../../viewer/scene/materials/EmphasisMaterial.js";


/**
 * Renders a 3D plane within an {@link Overview} to indicate its {@link SectionPlane}'s current position and orientation.
 *
 * @private
 */
class Plane {

    /** @private */
    constructor(overview, overviewScene, sectionPlane) {

        /**
         * The ID of this SectionPlanesOverviewPlane.
         *
         * @type {String}
         */
        this.id = sectionPlane.id;

        /**
         * The {@link SectionPlane} represented by this SectionPlanesOverviewPlane.
         *
         * @type {SectionPlane}
         */
        this._sectionPlane = sectionPlane;

        this._mesh = new Mesh(overviewScene, {
            id: sectionPlane.id,
            geometry: new ReadableGeometry(overviewScene, buildBoxGeometry({
                xSize: .5,
                ySize: .5,
                zSize: .001
            })),
            material: new PhongMaterial(overviewScene, {
                emissive: [1, 1, 1],
                diffuse: [0, 0, 0],
                backfaces: false
            }),
            edgeMaterial: new EdgeMaterial(overviewScene, {
                edgeColor: [0.0, 0.0, 0.0],
                edgeAlpha: 1.0,
                edgeWidth: 1
            }),
            highlightMaterial: new EmphasisMaterial(overviewScene, {
                fill: true,
                fillColor: [0.5, 1, 0.5],
                fillAlpha: 0.7,
                edges: true,
                edgeColor: [0.0, 0.0, 0.0],
                edgeAlpha: 1.0,
                edgeWidth: 1
            }),
            selectedMaterial: new EmphasisMaterial(overviewScene, {
                fill: true,
                fillColor: [0, 0, 1],
                fillAlpha: 0.7,
                edges: true,
                edgeColor: [1.0, 0.0, 0.0],
                edgeAlpha: 1.0,
                edgeWidth: 1
            }),
            highlighted: true,
            scale: [3, 3, 3],
            position: [0, 0, 0],
            rotation: [0, 0, 0],
            opacity: 0.3,
            edges: true
        });


        {
            const vec = math.vec3([0, 0, 0]);
            const pos2 = math.vec3();
            const zeroVec = math.vec3([0, 0, 1]);
            const quat = math.vec4(4);
            const pos3 = math.vec3();

            const update = () => {

                const origin = this._sectionPlane.scene.center;

                const negDir = [-this._sectionPlane.dir[0], -this._sectionPlane.dir[1], -this._sectionPlane.dir[2]];
                math.subVec3(origin, this._sectionPlane.pos, vec);
                const dist = -math.dotVec3(negDir, vec);

                math.normalizeVec3(negDir);
                math.mulVec3Scalar(negDir, dist, pos2);
                const quaternion = math.vec3PairToQuaternion(zeroVec, this._sectionPlane.dir, quat);

                pos3[0] = pos2[0] * 0.1;
                pos3[1] = pos2[1] * 0.1;
                pos3[2] = pos2[2] * 0.1;

                this._mesh.quaternion = quaternion;
                this._mesh.position = pos3;
            };

            this._onSectionPlanePos = this._sectionPlane.on("pos", update);
            this._onSectionPlaneDir = this._sectionPlane.on("dir", update);

            // update();
        }

        this._highlighted = false;
        this._selected = false;
    }

    /**
     * Sets if this SectionPlanesOverviewPlane is highlighted.
     *
     * @type {Boolean}
     * @private
     */
    setHighlighted(highlighted) {
        this._highlighted = !!highlighted;
        this._mesh.highlighted = this._highlighted;
        this._mesh.highlightMaterial.fillColor = highlighted ? [0, 0.7, 0] : [0, 0, 0];
        // this._selectedMesh.highlighted = true;
    }

    /**
     * Gets if this SectionPlanesOverviewPlane is highlighted.
     *
     * @type {Boolean}
     * @private
     */
    getHighlighted() {
        return this._highlighted;
    }

    /**
     * Sets if this SectionPlanesOverviewPlane is selected.
     *
     * @type {Boolean}
     * @private
     */
    setSelected(selected) {
        this._selected = !!selected;
        this._mesh.edgeMaterial.edgeWidth = selected ? 3 : 1;
        this._mesh.highlightMaterial.edgeWidth = selected ? 3 : 1;

    }

    /**
     * Gets if this SectionPlanesOverviewPlane is selected.
     *
     * @type {Boolean}
     * @private
     */
    getSelected() {
        return this._selected;
    }

    /** @private */
    destroy() {
        this._sectionPlane.off(this._onSectionPlanePos);
        this._sectionPlane.off(this._onSectionPlaneDir);
        this._mesh.destroy();
    }
}

export {Plane};
