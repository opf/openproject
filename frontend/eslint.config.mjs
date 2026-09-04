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

import eslint from '@eslint/js';
import { readFileSync } from 'node:fs';
import globals from 'globals';
import { fileURLToPath } from 'node:url';
import tseslint from 'typescript-eslint';
import vitest from '@vitest/eslint-plugin';
import angular from 'angular-eslint';
import stylistic from '@stylistic/eslint-plugin';
import headers from 'eslint-plugin-headers';
import tsdoc from 'eslint-plugin-tsdoc';

import { defineConfig, globalIgnores } from 'eslint/config';

const copyrightPath = fileURLToPath(new URL('../COPYRIGHT_short', import.meta.url));
const copyrightHeader = [
  '-- copyright',
  ...readFileSync(copyrightPath, 'utf8')
    .trimEnd()
    .split(/\r?\n/)
    .map((line) => line ? ` ${line}` : ''),
  '++',
].join('\n');

export default defineConfig([
  {
    files: ['**/*.{js,mjs,cjs,ts,tsx,mts,cts}'],
    plugins: { headers },
    rules: {
      'headers/header-format': [
        'error',
        {
          source: 'string',
          content: copyrightHeader,
          style: 'line',
          linePrefix: '',
          trailingNewlines: 2,
        },
      ],
    },
  },
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [
      eslint.configs.recommended
    ],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.browser, ...globals.node }
    }
  },
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommendedTypeChecked,
      ...tseslint.configs.stylisticTypeChecked,
      ...angular.configs.tsRecommended
    ],
    processor: angular.processInlineTemplates,
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
      globals: { ...globals.browser, ...globals.node },
    },
    rules: {
      /**
       * Any TypeScript source code (NOT TEMPLATE) related rules you wish to use/reconfigure over and above the
       * recommended set provided by the @angular-eslint project would go here.
       */
      '@angular-eslint/directive-selector': [
        'error',
        { type: 'attribute', prefix: ['op', 'opce'], style: 'camelCase' },
      ],
      '@angular-eslint/component-selector': ['error', { type: 'element', prefix: ['op', 'opce'], style: 'kebab-case' }],
      '@angular-eslint/component-class-suffix': ['error', { suffixes: ['Component', 'Example'] }],

      '@angular-eslint/prefer-standalone': 'off',

      // Warn when new components are being created without OnPush
      '@angular-eslint/prefer-on-push-component-change-detection': 'error',
      'no-console': [
        'error',
        {
          allow: ['warn', 'error'],
        },
      ],

      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { varsIgnorePattern: '^_', argsIgnorePattern: '^_' }],

      // Allow short circuit evaluations
      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true }],

      // Disable order style as it's not compatible with intellij import organization
      'import/order': 'off',

      // It'd be good if we could error this for switch cases but allow it for for loops
      'no-continue': 'off',

      // no param reassignment is a pain when trying to set props on elements
      'no-param-reassign': 'off',

      // destructuring doesn't always look better, only when object/array destructuring
      'prefer-destructuring': 'off',

      // Sometimes, arrow functions look better broken down
      'arrow-body-style': 'off',

      // No void at all collides with `@typescript-eslint/no-floating-promises` which wants us to handle each promise.
      // Until we do that, `void` is a good way to explicitly mark unhandled promises.
      'no-void': ['error', { allowAsStatement: true }],

      // Disable no-use for functions and classes
      'no-use-before-define': ['error', { functions: false, classes: false }],
      '@typescript-eslint/no-use-before-define': ['error', { functions: false, classes: false }],

      // Allow namespaces, they are generated into flat functions and we don't care about modules for helpers
      '@typescript-eslint/no-namespace': 'off',

      /*
      // Disable use before define, as irrelevant for TS interfaces
        'no-use-before-define': 'off',
        '@typescript-eslint/no-use-before-define': 'off',
      */

      // Allow writing type union and type intersections without space
      '@typescript-eslint/space-infix-ops': 'off',

      // Allow empty interfaces for naming purposes (HAL resources)
      '@typescript-eslint/no-empty-object-type': ['warn', { allowInterfaces: 'always' }],

      'import/prefer-default-export': 'off',

      'import/no-cycle': 'off',

      // HAL has a lot of dangling properties, so allow
      // usage in properties but not in all other places
      'no-underscore-dangle': [
        'warn',
        {
          allow: ['_links', '_embedded', '_meta', '_type', '_destroy'],
          allowAfterThis: true,
          allowAfterSuper: false,
          allowAfterThisConstructor: false,
          enforceInMethodNames: true,
          allowFunctionParams: true,
        },
      ],

      'no-return-assign': ['error', 'except-parens'],
      'no-plusplus': ['error', { allowForLoopAfterthoughts: true }],

      // https://typescript-eslint.io/rules/no-base-to-string/ Disable false positives due to missing types
      '@typescript-eslint/no-base-to-string': [
        'error',
        { ignoredTypeNames: ['URI', 'Error', 'RegExp', 'URL', 'URLSearchParams'] },
      ],

      //////////////////////////////////////////////////////////////////////
      // Anything below this line should be turned on again at some point //
      //////////////////////////////////////////////////////////////////////

      // It's common in Angular to wrap even pure functions in classes for injection purposes
      'class-methods-use-this': 'off',
    },
  },
  {
    files: ['**/*.html'],
    extends: [
      ...angular.configs.templateRecommended,
      ...angular.configs.templateAccessibility,
    ],
    rules: {
      '@angular-eslint/template/click-events-have-key-events': [
        'error',
        { 'ignoreWithDirectives': ['uiSref'] }
      ],
      '@angular-eslint/template/elements-content': [
        'error',
        { 'allowList': ['textContent'] }
      ],
      '@angular-eslint/template/prefer-control-flow': 'error'
    }
  },
  {
    files: ['**/*.spec.ts'],
    ...vitest.configs.recommended,
    rules: {
      ...vitest.configs.recommended.rules,

      // vitest expect(...) is always any
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',

      // Allow more than one class definitions per file (test components)
      'max-classes-per-file': 'off',
    },
  },
  {
    // Scoped to the `entryPoints` of `typedoc.json`; widen alongside it.
    files: ['src/stimulus/**/*.ts'],
    plugins: { tsdoc },
    rules: {
      'tsdoc/syntax': 'error',
    },
  },
  {
    plugins: { '@stylistic': stylistic },
    rules: {
      '@stylistic/semi': ['error', 'always'],

      // Who cares about line length
      '@stylistic/max-len': 'off',

      // Disable forcing newlines in braces to prevent empty objects and import errors
      '@stylistic/object-curly-newline': 'off',

      // Force single quotes to align with ruby
      '@stylistic/quotes': ['error', 'single', { avoidEscape: true }],

      // Sometimes, arrow functions implicit return looks better below, so allow both
      '@stylistic/implicit-arrow-linebreak': 'off',

      // Allow subsequent single fields in typescript classes
      '@stylistic/lines-between-class-members': ['error', 'always', { exceptAfterSingleLine: true }],

      // Disable indentation rule as it breaks in edge cases and is covered by editorconfig
      '@stylistic/indent': 'off',

      // Whitespace configuration: spaces around the function-type `=>`
      // (defaults), but tight colons. Colon spacing lives in
      // `overrides.colon` because the rule's `overrides.arrow` option is
      // deprecated; keeping the base spaced preserves `() => void` style.
      '@stylistic/type-annotation-spacing': [
        'error',
        {
          before: true,
          after: true,
          overrides: {
            colon: {
              before: false,
              after: false,
            },
          },
        },
      ],

      '@stylistic/spaced-comment': 'off',
    },
  },
  globalIgnores([
    '**/.eslintrc.js',
    'coverage/',
    '**/vendor',
    // Carries a third-party copyright notice; excluded from `rake copyright:update_*` too.
    'src/app/features/plugins/linked/openproject-gitlab_integration/**',
  ]),
]);
