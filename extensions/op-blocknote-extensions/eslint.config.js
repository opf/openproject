import eslint from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';
import vitest from '@vitest/eslint-plugin';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import stylistic from '@stylistic/eslint-plugin';

import { defineConfig, globalIgnores } from 'eslint/config';

export default defineConfig([
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [
      eslint.configs.recommended,
    ],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.browser, ...globals.node },
    },
  },
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommendedTypeChecked,
      ...tseslint.configs.stylisticTypeChecked,
    ],
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    languageOptions: {
      parserOptions: {
        projectService: {
          allowDefaultProject: [
            'vite.config.ts',
            'vitest.config.ts',
            'vitest.browser.config.ts',
            'global.d.ts',
          ],
          defaultProject: './tsconfig.test.json',
        },
        tsconfigRootDir: import.meta.dirname,
      },
      globals: { ...globals.browser, ...globals.node },
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],

      'no-console': ['error', { allow: ['warn', 'error'] }],

      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { varsIgnorePattern: '^_', argsIgnorePattern: '^_' }],

      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true }],

      'no-continue': 'off',
      'no-param-reassign': 'off',
      'prefer-destructuring': 'off',
      'arrow-body-style': 'off',

      'no-void': ['error', { allowAsStatement: true }],

      'no-use-before-define': ['error', { functions: false, classes: false }],
      '@typescript-eslint/no-use-before-define': ['error', { functions: false, classes: false }],

      '@typescript-eslint/no-namespace': 'off',

      '@typescript-eslint/space-infix-ops': 'off',

      '@typescript-eslint/no-empty-object-type': ['warn', { allowInterfaces: 'always' }],

      '@typescript-eslint/no-base-to-string': [
        'error',
        { ignoredTypeNames: ['URI', 'Error', 'RegExp', 'URL', 'URLSearchParams'] },
      ],

      'no-underscore-dangle': [
        'warn',
        {
          allow: ['_links', '_embedded', '_meta', '_type', '_destroy', '_tiptapEditor', '__dirname'],
          allowAfterThis: true,
          allowAfterSuper: false,
          allowAfterThisConstructor: false,
          enforceInMethodNames: true,
          allowFunctionParams: true,
        },
      ],

      'no-return-assign': ['error', 'except-parens'],
      'no-plusplus': ['error', { allowForLoopAfterthoughts: true }],

      'class-methods-use-this': 'off',
    },
  },
  {
    files: ['**/*.spec.ts', '**/*.test.ts', '**/*.test.tsx'],
    ...vitest.configs.recommended,
    rules: {
      ...vitest.configs.recommended.rules,

      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/require-await': 'off',

      'max-classes-per-file': 'off',
      'vitest/no-commented-out-tests': 'off',
    },
  },
  {
    files: ['test/**/*.ts', 'test/**/*.tsx'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-unsafe-argument': 'off',
      '@typescript-eslint/no-unsafe-member-access': 'off',
      '@typescript-eslint/no-unsafe-call': 'off',
      '@typescript-eslint/require-await': 'off',
      '@typescript-eslint/no-floating-promises': 'off',
      '@typescript-eslint/await-thenable': 'off',
      '@typescript-eslint/no-empty-function': 'off',
      '@typescript-eslint/no-unused-vars': 'off',
      'react-refresh/only-export-components': 'off',
    },
  },
  {
    files: ['lib/**/*.{ts,tsx}'],
    rules: {
      'react-refresh/only-export-components': 'off',
    },
  },
  {
    plugins: { '@stylistic': stylistic },
    rules: {
      '@stylistic/semi': ['error', 'always'],
      '@stylistic/max-len': 'off',
      '@stylistic/object-curly-newline': 'off',
      '@stylistic/quotes': ['error', 'single', { avoidEscape: true }],
      '@stylistic/implicit-arrow-linebreak': 'off',
      '@stylistic/lines-between-class-members': ['error', 'always', { exceptAfterSingleLine: true }],
      '@stylistic/indent': 'off',
      '@stylistic/type-annotation-spacing': [
        'error',
        {
          before: false,
          after: false,
          overrides: {
            arrow: { before: true, after: true },
          },
        },
      ],
      '@stylistic/spaced-comment': 'off',
    },
  },
  globalIgnores([
    'dist/',
    'coverage/',
    '**/vendor',
    'lib/locales/crowdin/',
  ]),
]);
