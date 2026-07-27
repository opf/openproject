//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
