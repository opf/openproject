/**
 * @desc A **Material** defines the surface appearance of attached {@link Mesh}es.
 *
 * Material is the base class for:
 *
 * * {@link MetallicMaterial} - physically-based material for metallic surfaces. Use this one for things made of metal.
 * * {@link SpecularMaterial} - physically-based material for non-metallic (dielectric) surfaces. Use this one for insulators, such as ceramics, plastics, wood etc.
 * * {@link PhongMaterial} - material for classic Blinn-Phong shading. This is less demanding of graphics hardware than the physically-based materials.
 * * {@link LambertMaterial} - material for fast, flat-shaded CAD rendering without textures. Use this for navigating huge CAD or BIM models interactively. This material gives the best rendering performance and uses the least memory.
 * * {@link EmphasisMaterial} - defines the appearance of Meshes when "xrayed" or "highlighted".
 * * {@link EdgeMaterial} - defines the appearance of Meshes when edges are emphasized.
 *
 * A {@link Scene} is allowed to contain a mixture of these material types.
 *
 */
import {Component} from '../Component.js';
import {stats} from '../stats.js';

class Material extends Component {

    /**
     @private
     */
    get type() {
        return "Material";
    }

    constructor(owner, cfg={}) {
        super(owner, cfg);
        stats.memory.materials++;
    }

    destroy() {
        super.destroy();
        stats.memory.materials--;
    }
}

export {Material};
