/**
 * @desc Represents a vertex or fragment stage within a {@link Program}.
 * @private
 */
class Shader {

    constructor(gl, type, source) {

        this.allocated = false;
        this.compiled = false;
        this.handle = gl.createShader(type);

        if (!this.handle) {
            this.errors = [
                "Failed to allocate"
            ];
            return;
        }

        this.allocated = true;

        gl.shaderSource(this.handle, source);
        gl.compileShader(this.handle);

        this.compiled = gl.getShaderParameter(this.handle, gl.COMPILE_STATUS);

        if (!this.compiled) {

            if (!gl.isContextLost()) { // Handled explicitly elsewhere, so won't re-handle here

                const lines = source.split("\n");
                const numberedLines = [];
                for (let i = 0; i < lines.length; i++) {
                    numberedLines.push((i + 1) + ": " + lines[i] + "\n");
                }
                this.errors = [];
                this.errors.push("");
                this.errors.push(gl.getShaderInfoLog(this.handle));
                this.errors = this.errors.concat(numberedLines.join(""));
            }
        }
    }

    destroy() {

    }
}

export {Shader};