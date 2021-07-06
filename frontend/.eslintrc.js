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

        "no-console": [
          "error",
          {
            allow: [
              "warn",
              "error",
            ],
          },
        ],

        // Who cares about line lenght
        "max-len": "off",

        // Force single quotes to align with ruby
        quotes: "off",
        "@typescript-eslint/quotes": ["error", "single", { avoidEscape: true }],

        // Disable webpack loader definitions
        "import/no-webpack-loader-syntax": "off",

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

        //////////////////////////////////////////////////////////////////////
        // Anything below this line should be turned on again at some point //
        //////////////////////////////////////////////////////////////////////

        // It's common in Angular to wrap even pure functions in classes for injection purposes
        // TODO: Should probably be turned off and pure unit tests should be used at some point
        "class-methods-use-this": "warn",

        // There's too much interop with legacy code that is `any`-typed for this to be an error in any practical sense
        // TODO: Actually type everything
        "@typescript-eslint/no-unsafe-member-access": "warn",
        "@typescript-eslint/no-unsafe-assignment": "warn",
        "@typescript-eslint/no-unsafe-call": "warn",

        // This is probably the first rule that should be fixed. It had 309 errors last time we checked
        "@typescript-eslint/no-unsafe-return": "warn",
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
      }
    }
  ],
};
