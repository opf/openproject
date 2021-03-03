module.exports = {
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/eslint-recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
  ],
  env: {
    browser: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: "./src/tsconfig.app.json",
    sourceType: "module",
    createDefaultProgram: true,
  },
  plugins: [
    "@typescript-eslint",
  ],
  rules: {
    "@typescript-eslint/dot-notation": "off",
    "@typescript-eslint/naming-convention": "off",
    "@typescript-eslint/no-empty-function": "error",
    // note you must disable the base rule as it can report incorrect errors
    semi: "off",
    "@typescript-eslint/semi": ["error"],
    "brace-style": [
      "error",
      "1tbs",
    ],
    curly: "error",
    "eol-last": "off",
    eqeqeq: [
      "error",
      "smart",
    ],
    "guard-for-in": "error",
    "id-blacklist": "off",
    "id-match": "off",
    "max-len": [
      "off",
      {
        code: 140,
      },
    ],
    "no-bitwise": "off",
    "no-caller": "error",
    "no-console": [
      "error",
      {
        allow: [
          "log",
          "warn",
          "dir",
          "timeLog",
          "assert",
          "clear",
          "count",
          "countReset",
          "group",
          "groupEnd",
          "table",
          "dirxml",
          "error",
          "groupCollapsed",
          "Console",
          "profile",
          "profileEnd",
          "timeStamp",
          "context",
        ],
      },
    ],
    "no-debugger": "error",
    "no-empty": "error",
    "no-eval": "error",
    "no-new-wrappers": "error",
    "no-redeclare": "error",
    "no-trailing-spaces": "error",
    "no-underscore-dangle": "off",
    "no-unused-labels": "error",
    "no-var": "off",
    radix: "off",
    // Disable required spaces in license comments
    "spaced-comment": "off",

    // Disable preference on quotes, rely on formatter instead
    quotes: "off",

    // Disable imports not matching package names
    "import/no-extraneous-dependencies": "off",

    // Disable specifying import extensions as TS does not support it
    "import/extensions": "off",

    // Disable eslint not being able to resolve imports, handled by TS
    "import/no-unresolved": "off",

    // Disable consistent return as typescript checks return type
    "consistent-return": "off",

    // Disable forcing arrow function params for one
    "arrow-parens": "off",

    // Disable enforce class methods use this
    "class-methods-use-this": "off",

    // Disable webpack loader definitions
    "import/no-webpack-loader-syntax": "off",

    // Disable use before define, as irrelevant for TS interfaces
    "no-use-before-define": "off",
    "@typescript-eslint/no-use-before-define": "off",

    // Allow object.hasOwnProperty calls
    "no-prototype-builtins": "off",

    // We need to redeclare interface with the same name
    // as a class or constant for type ducking
    "no-redeclare": "off",

    // Whitespace configuration
    "@typescript-eslint/type-annotation-spacing": [
      "error",
      {
        before: false,
        after: false,
        overrides: {
          arrow: {
            before: true,
            after: true,
          },
        },
      },
    ],

    // Allow empty interfaces for naming purposes (HAL resources)
    "@typescript-eslint/no-empty-interface": "off",

    // Force spaces in objects
    "object-curly-spacing": ["error", "always"],

    // Force indent to 2space
    indent: ["error", 2],
  },
};
