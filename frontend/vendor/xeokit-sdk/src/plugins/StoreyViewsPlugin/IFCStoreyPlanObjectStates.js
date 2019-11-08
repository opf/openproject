/**
 * @desc Property states for {@link Entity}s in {@link Storey}s capture by a {@link StoreyViewsPlugin}.
 *
 * @type {{String:Object}}
 */
const IFCStoreyPlanObjectStates = {
    IfcSlab: {
        visible: true,
        edges: false,
        colorize: [1.0, 1.0, 1.0, 1.0]
    },
    IfcWall: {
        visible: true,
        edges: false,
        colorize: [0.1, 0.1, 0.1, 1.0]
    },
    IfcWallStandardCase: {
        visible: true,
        edges: false,
        colorize: [0.1, 0.1, 0.1, 1.0]
    },
    IfcDoor: {
        visible: true,
        edges: false,
        colorize: [0.5, 0.5, 0.5, 1.0]
    },
    IfcWindow: {
        visible: true,
        edges: false,
        colorize: [0.5, 0.5, 0.5, 1.0]
    },
    IfcColumn: {
        visible: true,
        edges: false,
        colorize: [0.5, 0.5, 0.5, 1.0]
    },
    IfcCurtainWall: {
        visible: true,
        edges: false,
        colorize: [0.5, 0.5, 0.5, 1.0]
    },
    IfcStair: {
        visible: true,
        edges: false,
        colorize: [0.7, 0.7, 0.7, 1.0]
    },
    IfcStairFlight: {
        visible: true,
        edges: false,
        colorize: [0.7, 0.7, 0.7, 1.0]
    },
    IfcRamp: {
        visible: true,
        edges: false,
        colorize: [0.7, 0.7, 0.7, 1.0]
    },
    IfcFurniture: {
        visible: true,
        edges: false,
        colorize: [0.7, 0.7, 0.7, 1.0]
    },
    IfcFooting: {
        visible: true,
        edges: false,
        colorize: [0.7, 0.7, 0.7, 1.0]
    },
    IfcFloor: {
        visible: true,
        edges: false,
        colorize: [1.0, 1.0, 1.0, 1.0]
    },
    DEFAULT: {
        visible: false
    }
};

export {IFCStoreyPlanObjectStates}