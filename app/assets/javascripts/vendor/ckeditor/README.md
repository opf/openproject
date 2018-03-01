# OpenProject CKEditor5 build repository

This build contains the vendored CKEditor5 commonmark build from `@openproject/commonmark-ckeditor-build`

For building this on your own

[https://github.com/opf/commonmark-ckeditor-build](https://github.com/opf/commonmark-ckeditor-build)


## Development

1. Download the package

2. Make your changes

3. Run `npm run webpack-watch` while developing

4. Symlink the dists for easy reloading:

```bash
ln -fs /path/to/commonmark-ckeditor-build/dist/openproject-ckeditor.js app/assets/javascripts/vendor/ckeditor/openproject-ckeditor.min.js
```

3. Run `npm run dist`

4. Update the vendored files here
