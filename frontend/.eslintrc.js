module.exports = {
  extends: [
    "eslint:recommended",
  ],
  env: {
    browser: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: "./src/tsconfig.app.json",
    tsconfigRootDir: __dirname,
    sourceType: "module",
    createDefaultProgram: true,
  },
  plugins: [
    "@typescript-eslint",
    "change-detection-strategy",
    "jasmine",
  ],
  overrides: [
    {
      files: ["*.ts"],
      parser: "@typescript-eslint/parser",
      parserOptions: {
        project: "./src/tsconfig.app.json",
        tsconfigRootDir: __dirname,
        sourceType: "module",
        createDefaultProgram: true
      },
      extends: [
        "plugin:@typescript-eslint/recommended",
        "plugin:@typescript-eslint/recommended-requiring-type-checking",
        "plugin:@angular-eslint/recommended",
        // This is required if you use inline templates in Components
        "plugin:@angular-eslint/template/process-inline-templates",
        "airbnb-typescript",
      ],
      rules: {
        /**
         * Any TypeScript source code (NOT TEMPLATE) related rules you wish to use/reconfigure over and above the
         * recommended set provided by the @angular-eslint project would go here.
         */
        "@angular-eslint/directive-selector": [
          "error",
          { "type": "attribute", "prefix": "op", "style": "camelCase" }
        ],
        "@angular-eslint/component-selector": [
          "error",
          { "type": "element", "prefix": "op", "style": "kebab-case" }
        ],

        // Warn when new components are being created without OnPush
        "change-detection-strategy/on-push": "error",

        "no-console": [
          "error",
          {
            allow: [
              "warn",
              "error",
            ],
          },
        ],

        // Who cares about line length
        "max-len": "off",

        // Force single quotes to align with ruby
        quotes: "off",
        "@typescript-eslint/quotes": ["error", "single", { avoidEscape: true }],

        // Disable webpack loader definitions
        "import/no-webpack-loader-syntax": "off",
        // Disable order style as it's not compatible with intellij import organization
        "import/order": "off",

        // It'd be good if we could error this for switch cases but allow it for for loops
        "no-continue": "off",

        // No void at all collides with `@typescript-eslint/no-floating-promises` which wants us to handle each promise.
        // Until we do that, `void` is a good way to explicitly mark unhandled promises. 
        "no-void": ["error", { allowAsStatement: true }],

        /*
        // Disable use before define, as irrelevant for TS interfaces
        "no-use-before-define": "off",
        "@typescript-eslint/no-use-before-define": "off",
        */

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

        "import/prefer-default-export": "off",

        // HAL has a lot of dangling properties, so allow
        // usage in properties but not in all other places
        "no-underscore-dangle": [
          "warn",
          {
            allow: [
              "_links",
              "_embedded",
              "_meta",
            ],
            allowAfterThis: false,
            allowAfterSuper: false,
            allowAfterThisConstructor: false,
            enforceInMethodNames: true,
            allowFunctionParams: false,
          }
        ],

        "no-return-assign": ["error", "except-parens"],
        "no-plusplus": ["error", { "allowForLoopAfterthoughts": true }],

        //////////////////////////////////////////////////////////////////////
        // Anything below this line should be turned on again at some point //
        //////////////////////////////////////////////////////////////////////

        // It's common in Angular to wrap even pure functions in classes for injection purposes
        "class-methods-use-this": "off",
      }
    },
    {
      files: ["*.html"],
      extends: ["plugin:@angular-eslint/template/recommended"],
      rules: {
        /**
         * Any template/HTML related rules you wish to use/reconfigure over and above the
         * recommended set provided by the @angular-eslint project would go here.
         */
        "@angular-eslint/template/no-call-expression": 2,
      }
    },
    {
      files: ["*.spec.ts"],
      extends: ["plugin:jasmine/recommended"],
      rules: {
        /**
         * Any template/HTML related rules you wish to use/reconfigure over and above the
         * recommended set provided by the @angular-eslint project would go here.
         */

        // jasmine is unusable with unsafe member access, as expect(...) is always any
        "@typescript-eslint/no-unsafe-member-access": "off",
        "@typescript-eslint/no-unsafe-call": "off",

        // Allow more than one class definitions per file (test components)
        "max-classes-per-file": "off",
      }
    }
  ],
};
