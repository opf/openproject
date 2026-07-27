import js from "@eslint/js";
import { readFileSync } from "node:fs";
import globals from "globals";
import { fileURLToPath } from "node:url";
import tseslint from "typescript-eslint";
import json from "@eslint/json";
import { defineConfig } from "eslint/config";
import stylistic from "@stylistic/eslint-plugin";
import headers from "eslint-plugin-headers";

const copyrightPath = fileURLToPath(new URL("../../COPYRIGHT_short", import.meta.url));
const copyrightHeader = [
  "-- copyright",
  ...readFileSync(copyrightPath, "utf8")
    .trimEnd()
    .split(/\r?\n/)
    .map((line) => line ? ` ${line}` : ""),
  "++",
].join("\n");

export default defineConfig([
  {
    ignores: ["package-lock.json"],
  },
  tseslint.configs.recommended,
  {
    files: ["**/*.{js,mjs,cjs,ts,tsx,mts,cts}"],
    plugins: {
      js,
      '@stylistic': stylistic,
      headers,
    },
    extends: ["js/recommended"],
    languageOptions: { globals: globals.node },
    rules: {
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["warn", {
        argsIgnorePattern: "^[A-Z_]",
        varsIgnorePattern: "^[A-Z_]",
        caughtErrorsIgnorePattern: "^[A-Z_]",
      }],
      "@stylistic/semi": ["warn", "always"],
      "@stylistic/indent": ["warn", 2],
      "headers/header-format": [
        "error",
        {
          source: "string",
          content: copyrightHeader,
          style: "line",
          linePrefix: "",
          trailingNewlines: 2,
        },
      ],
    }
  },
  {
    files: ["**/*.ts"],
    rules: {
      "no-undef": "off",
    },
  },
  {
    files: ["**/*.json"],
    plugins: { json },
    language: "json/json",
    extends: ["json/recommended"]
  },
]);
