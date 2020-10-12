# OpenProject Textile to Markdown migration

<div class="alert alert-info" role="alert">

**Note**: This guide concerns a legacy version of OpenProject (8.0.0). This only affects your system if you try to upgrade to a newer version from OpenProject 7.4 or lower.

</div>

OpenProject 8.0.0. includes a switch away from Textile syntax formatting to Markdown. Pandoc is used for the conversion of all formattable texts in your existing OpenProject instance.

## Applicable Instances

All instances that have run OpenProject prior to 8.0.0. must be converted in order to maintain the integrity of all formattable resources such as wiki pages, work packages, meetings, posts, comments, journals and so on.

The migration will be performed automatically during your upgrade to 8.0. You will find additional information to prevent or postpone the migration down below.



## Dependencies

We depend on `pandoc` (http://pandoc.org/) for the conversion of all formattable fields in OpenProject. It provides automated means to migrate between many input and output formats, in our case from Textile to GitHub-flavored Markdown.

If you do not have an executable pandoc version of at least version 2.0 in your path, OpenProject will try download an AMD64 static linked binary for pandoc (Currently, this would be version 2.3.2). This version will be made available to OpenProject through `<OpenProject root>/vendor/pandoc` and is only used during that one-time migration step.

If you want to force a specific version within your path, set the environment variable OPENPROJECT_PANDOC_PATH, e.g., `OPENPROJECT_PANDOC_PATH=/opt/my/pandoc/bin/pandoc`.



## CommonMark

Our Markdown parsers and formatters operate on the [CommonMark Markdown standard](https://commonmark.org/) with some suggested additions not yet part of the standard formalized in the [GitHub-flavored Markdown spec.](https://github.github.com/gfm/)



## Skipping the migration

If you want to skip the migration during the upgrade of 8.0. (e.g., because you want it to run asynchronously), please set the environment variable `OPENPROJECT_SKIP_TEXTILE_MIGRATION="true"` .

This will print a warning and then continue with the migration. You can manually force the migration with the following command. **Warning:** Be careful not to execute this once you have already migrated to Markdown because the converter does not distinguish between input formats and simply iterates over all values.



        $> bundle exec rails runner "OpenProject::TextFormatting::Formats::Markdown::TextileConverter.new.run!"

or in a packaged installation:

```
    $> openproject run bundle exec rails runner "OpenProject::TextFormatting::Formats::Markdown::TextileConverter.new.run!"
```



## Markdown and WYSIWYG features

With the migration of Markdown, we have introduced a quasi-WYSIWYG powerd by CKEditor5  that will make editing in all formattable fields of OpenProject much easier. The output format of that editor is still Markdown.



For information regarding the features of Markdown and the capabilities of the CKEditor WYSIWYG editor built upon it, please see https://docs.openproject.org/user-guide/wiki/.



## Textile in 8.0.0.

OpenProject does no longer support Textile in 8.0.0 because it is infeasible to support both variants. Please reach out to us if you're interested in maintaining a Textile format as a plugin. 

