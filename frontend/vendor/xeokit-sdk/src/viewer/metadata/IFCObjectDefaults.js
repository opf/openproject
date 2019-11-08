/**
 * @desc Default initial properties for {@link Entity}s loaded from models accompanied by metadata.
 *
 * When loading a model, a loader plugins such as {@link GLTFLoaderPlugin} and {@link BIMServerLoaderPlugin} create
 * a tree of {@link Entity}s that represent the model. These loaders can optionally load metadata, to create
 * a {@link MetaModel} corresponding to the root {@link Entity}, with a {@link MetaObject} corresponding to each
 * object {@link Entity} within the tree.
 *
 * @type {{String:Object}}
 */
const IFCObjectDefaults = {

    // Priority 0

    IfcRoof: {
        colorize: [0.837255, 0.203922, 0.270588],
        priority: 0
    },
    IfcSlab: {
        colorize: [0.637255, 0.603922, 0.670588],
        priority: 0
    },
    IfcWall: {
        colorize: [0.537255, 0.337255, 0.237255],
        priority: 0
    },
    IfcWallStandardCase: {
        colorize: [0.537255, 0.337255, 0.237255],
        priority: 0
    },
    IfcCovering: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 0
    },

    // Priority 1

    IfcDoor: {
        colorize: [0.637255, 0.603922, 0.670588],
        priority: 1
    },

    // Priority 2

    IfcStair: {
        colorize: [0.637255, 0.603922, 0.670588],
        priority: 2
    },
    IfcStairFlight: {
        colorize: [0.637255, 0.603922, 0.670588],
        priority: 2
    },
    IfcProxy: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 2
    },
    IfcRamp: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 2
    },

    // Priority 3

    IfcColumn: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 3
    },
    IfcBeam: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 3
    },
    IfcCurtainWall: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 3
    },
    IfcPlate: {
        colorize: [0.8470588235, 0.427450980392, 0, 0.5],
        opacity: 0.5,
        priority: 3
    },
    IfcTransportElement: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 3
    },
    IfcFooting: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 3
    },

    // Priority 4

    IfcRailing: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 4
    },
    IfcFurnishingElement: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 4
    },
    IfcFurniture: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 4
    },
    IfcSystemFurnitureElement: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 4
    },

    // Priority 5

    IfcFlowSegment: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 5
    },
    IfcFlowitting: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 5
    },
    IfcFlowTerminal: {
        colorize: [0.137255, 0.403922, 0.870588],
        priority: 5
    },
    IfcFlowController: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 5
    },
    IfcFlowFitting: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 5
    },
    IfcDuctSegment: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 5
    },
    IfcDistributionFlowElement: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 5
    },
    IfcDuctFitting: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 5
    },
    IfcLightFixture: {
        colorize: [0.8470588235, 0.8470588235, 0.870588],
        priority: 5
    },

    // Priority 6

    IfcAirTerminal: {
        colorize: [0.8470588235, 0.427450980392, 0],
        priority: 6
    },

    IfcOpeningElement: {
        colorize: [0.137255, 0.403922, 0.870588],
        pickable: false,
        visible: false,
        priority: 6
    },
    IfcSpace: {
        colorize: [0.137255, 0.403922, 0.870588],
        pickable: false,
        visible: false,
        opacity: 0.5,
        priority: 6
    },

    IfcWindow: {
        colorize: [0.137255, 0.403922, 0.870588],
        pickable: false,
        opacity: 0.4,
        priority: 6 // FIXME: transparent objects need to be last in order to avoid strange wireframe effect
    },

    //

    IfcBuildingElementProxy: {
        colorize: [0.5, 0.5, 0.5]
    },

    IfcSite: {
        colorize: [0.137255, 0.403922, 0.870588]
    },

    IfcMember: {
        colorize: [0.8470588235, 0.427450980392, 0]
    },

    DEFAULT: {
        colorize: [0.5, 0.5, 0.5],
        priority: 10
    }
};

export {IFCObjectDefaults}