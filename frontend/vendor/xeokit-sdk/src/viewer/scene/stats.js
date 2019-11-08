/**
 * xeokit runtime statistics.
 * @private
 * @type {{components: {models: number, objects: number, scenes: number, meshes: number}, memory: {indices: number, uvs: number, textures: number, materials: number, transforms: number, positions: number, programs: number, normals: number, meshes: number, colors: number}, build: {version: string}, client: {browser: string}, frame: {frameCount: number, useProgram: number, bindTexture: number, drawElements: number, bindArray: number, tasksRun: number, fps: number, drawArrays: number, tasksScheduled: number}}}
 */
const stats = {
    build: {
        version: "0.8"
    },
    client: {
        browser: (navigator && navigator.userAgent) ? navigator.userAgent : "n/a"
    },

    components: {
        scenes: 0,
        models: 0,
        meshes: 0,
        objects: 0
    },
    memory: {
        meshes: 0,
        positions: 0,
        colors: 0,
        normals: 0,
        uvs: 0,
        indices: 0,
        textures: 0,
        transforms: 0,
        materials: 0,
        programs: 0
    },
    frame: {
        frameCount: 0,
        fps: 0,
        useProgram: 0,
        bindTexture: 0,
        bindArray: 0,
        drawElements: 0,
        drawArrays: 0,
        tasksRun: 0,
        tasksScheduled: 0
    }
};

export {stats};