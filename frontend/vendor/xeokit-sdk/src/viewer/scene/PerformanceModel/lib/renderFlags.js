/**
 * @private
 * @type {{PICKABLE: number, CLIPPABLE: number, BACKFACES: number, VISIBLE: number, SELECTED: number, OUTLINED: number, CULLED: number, RECEIVE_SHADOW: number, COLLIDABLE: number, XRAYED: number, CAST_SHADOW: number, EDGES: number, HIGHLIGHTED: number}}
 */
const RENDER_FLAGS = {
    VISIBLE: 1,
    CULLED: 1 << 2,
    PICKABLE: 1 << 3,
    CLIPPABLE: 1 << 4,
    COLLIDABLE: 1 << 5,
    CAST_SHADOW: 1 << 6,
    RECEIVE_SHADOW: 1 << 7,
    XRAYED: 1 << 8,
    HIGHLIGHTED: 1 << 9,
    SELECTED: 1 << 10,
    EDGES: 1 << 11,
    BACKFACES: 1 << 12
};

export {RENDER_FLAGS};