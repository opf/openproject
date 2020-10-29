#! /usr/bin/env node

const fs = require('fs');
const path = require('path');
const linked_module_example_path = path.join(__dirname, '..', 'src', 'app', 'modules', 'plugins', 'linked-plugins.module.ts.example');
const linked_module_path = path.join(__dirname, '..', 'src', 'app', 'modules', 'plugins', 'linked-plugins.module.ts');

var exists = fs.existsSync(linked_module_path);

if (!exists) {
    console.log(
        `Linked plugin path (${linked_module_path}) does not exist, using default. ` +
        `If you have active OpenProject plugins, run "rake openproject:plugins:register_frontend" to generate the file with the correct plugins being linked.`
    );

    var rd = fs.createReadStream(linked_module_example_path);
    var wr = fs.createWriteStream(linked_module_path);

    return new Promise(function(resolve, reject) {
        rd.on('error', reject);
        wr.on('error', reject);
        wr.on('finish', resolve);
        rd.pipe(wr);
    }).then(function() {
        console.log("Done.");
    }).catch(function(error) {
        rd.destroy();
        wr.end();

        console.error("Failed to write file: " + error);
        throw error;
    });
}
