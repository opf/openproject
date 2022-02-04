#! /usr/bin/env node

const fs = require('fs');
const path = require('path');
const linked_module_example_path = path.join(__dirname, '..', 'src', 'app', 'features', 'plugins', 'linked-plugins.module.ts.example');
const linked_style_example_path = path.join(__dirname, '..', 'src', 'app', 'features', 'plugins', 'linked-plugins.styles.sass.example');
const linked_module_path = path.join(__dirname, '..', 'src', 'app', 'features', 'plugins', 'linked-plugins.module.ts');
const linked_style_path = path.join(__dirname, '..', 'src', 'app', 'features', 'plugins', 'linked-plugins.styles.sass');

if (!fs.existsSync(linked_module_path)) {
  console.log(
    `Linked plugin path (${linked_module_path}) does not exist, using default. ` +
    `If you have active OpenProject plugins, run "rake openproject:plugins:register_frontend" to generate the file with the correct plugins being linked.`,
  );

  fs.copyFile(linked_module_example_path, linked_module_path, (err) => {
    if (err) throw err;
  });

}


if (!fs.existsSync(linked_style_path)) {
  console.log(
    `Linked sass path (${linked_style_path}) does not exist, using default. ` +
    `If you have active OpenProject plugins, run "rake openproject:plugins:register_frontend" to generate the file with the correct plugins being linked.`,
  );

  fs.copyFile(linked_style_example_path, linked_style_path, (err) => {
    if (err) throw err;
  });
}
