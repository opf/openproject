import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "node:path";

const __dirname = path.resolve();

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    lib: {
      entry: path.resolve(__dirname, "lib/index.ts"),
      name: "OpBlocknoteExtensions",
      formats: ["es"],
      fileName: (format) => `op-blocknote-extensions.${format}.js`,
    },
    rollupOptions: {
      // Externalize deps that shouldn't be bundled
      external: [
        "react",
        "react-dom",
        "@blocknote/core",
        "@blocknote/react",
        "@blocknote/mantine",
      ],
    },
  },
});
