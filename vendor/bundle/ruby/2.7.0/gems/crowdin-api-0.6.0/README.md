# Crowdin::API

A Ruby interface to the Crowdin API.

For more about the Crowdin API see <https://support.crowdin.com/api/api-integration-setup/>.

To experiment with that code, run `bin/console` for an interactive prompt.

> **WARNING**: This is a development version: It contains the latest changes, but may also have severe known issues, including crashes and data loss situations. In fact, it may not work at all.

## Installation

Add this line to your application's Gemfile:

```gemfile
gem 'crowdin-api'
```

And then execute:

```console
bundle
```

Or install it yourself as:

```console
gem install crowdin-api
```

## Usage

Start by creating a connection to Crowdin with your credentials:

Please note that almost all API calls require the `Project Identifier` and `Project API Key`.

```ruby
require 'crowdin-api'
require 'logger'

crowdin = Crowdin::API.new(api_key: API_KEY, project_id: PROJECT_ID)
crowdin.log = Logger.new $stderr
```

As well there are several API methods (`get_projects`, `create_project`) that require `User API Key` instead of regular `Project API Key`.

```ruby
crowdin = Crowdin::API.new(account_key: ACCOUNT_KEY)
```

Now you can make requests to the api.

### Add File

Add new file to Crowdin project.

Documentation:  <https://support.crowdin.com/api/add-file/>.

First parameter is array of files that should be added to Crowdin project.
Every file is hash:

* `:dest` - file name with path in Crowdin project (required)
* `:source` - file that should be added (required)
* `:title` - string that defines title for uploaded file (optional)
* `:export_pattern` - string that defines name of resulted file (optional)

Optional params:

* `:branch` - a branch name (optional)

**NOTE!** 20 files max are allowed to upload per one time file transfer.

```ruby
crowdin.add_file(
  files = [
    { dest: '/directory/array.xml', source: 'array.xml', export_pattern: '/values-%two_letters_code%/%original_file_name%' },
    { dest: 'strings.xml', source: 'strings.xml', title: 'Texts in Application' }
], type: 'android')
```

### Update File

Upload fresh version of your localization file.

Documentation <https://support.crowdin.com/api/update-file/>

First parameter is array of files that should be updated in Crowdin project.
Every file is hash:

* `:dest` - file name with path in Crowdin project (required)
* `:source` - uploaded file (required)
* `:title` - title for uploaded file (optional)
* `:export_pattern` - string that defines name of resulted file (optional)

Optional params:

* `:branch` - a branch name (optional)

**NOTE!** 20 files max are allowed to upload per one time file transfer.

```ruby
crowdin.update_file(
  files = [
    { :dest => '/directory/array.xml', :source => 'array.xml', :export_pattern => '/values-%two_letters_code%/%original_file_name%'},
    { :dest => 'strings.xml', :source => 'strings.xml' }
])

```

### Delete File

Remove file from Crowdin project.

Documentation <https://support.crowdin.com/api/delete-file/>

```ruby
crowdin.delete_file('strings.xml')
```

### Create Directory

Create a new directory in Crowdin project.

First parameter `name` - full directory path that should be created (e.g. /MainPage/AboutUs) (required)

Optional params:

* `:is_branch` - create new branch. Valid values - `'0'`, `'1'`. Only when create root directory.
* `:branch` - a branch name.

Documentation: <https://support.crowdin.com/api/add-directory/>

```ruby
crowdin.add_directory('dirname')
```

Create a new branch:

```ruby
crowdin.add_directory('master', is_branch: '1')
```

### Delete Directory

Remove directory with nested files from Crowdin project.

Optional params:

* `:branch` - a branch name (optional)

Documentation: <https://support.crowdin.com/api/delete-directory/>

```ruby
crowdin.delete_directory('dirname')
```

### Change Directory

Rename or change directory attributes.

Documentation: <https://support.crowdin.com/api/change-directory/>

First parameter `name` - full directory path that should be modified (e.g. /MainPage/AboutUs) (required)

Optional params:

* `:new_name` - new directory name
* `:title` - new directory title to be displayed in Crowdin UI
* `:export_pattern` - new direcrory export pattern. Is used to create directory name and path in resulted translations bundle.
* `:branch` - a branch name.


When renaming directory the path can not be changed (it means `new_name` parameter can not contain path, name only).

```ruby
crowdin.change_directory('/MainPage/AboutUs', new_name: 'AboutCompany')
```

### Upload Translations

Upload existing translations to your Crowdin project.

Documentation: <https://support.crowdin.com/api/upload-translation/>

First parameter is array of translated files that should be added to Crowdin project.
Every file is hash:

* `:dest` - file names in Crowdin (required)
* `:source` - uploaded translation (required)

Second parameter is target language.
With a single call it's possible to upload translations for several files but only into one of the languages.
Check [complete list of Crowdin language codes](https://support.crowdin.com/api/language-codes/) that can be used.

Optional params:

* `:import_duplicates` - defines whether to add translation if there is the same translation previously added (default: false)
* `:import_eq_suggestions` - defines whether to add translation if it is equal to source string at Crowdin (default: false)
* `:auto_approve_imported` - mark uploaded translations as approved (default: false)
* `:branch` - a branch name (default: nil)

**NOTE!** 20 files max are allowed to upload per one time file transfer.

```ruby
crowdin.upload_translation(
  files = [
    { :dest => 'strings.xml', :source => 'strings_uk.xml' },
    { :dest => 'array.xml', :source => 'array_uk.xml' }
  ],
  language = 'uk',
  params = {:import_duplicates => true}
)
```

### Download Translations

Download last exported translation package (one target language or all languages as one zip file).

Documentation: <https://support.crowdin.com/api/download/>

First parameter is the language of translation you need or download `all` of them at once.

Optional params:

* `:output` - a name of ZIP file with translations
* `:branch` - a branch name (default: nil)

```ruby
crowdin.download_translation('ru', :output => '/path/to/download/ru_RU.zip')
```

### Translation Status

Track overall translation and proofreading progress of each target language.

Documentation: <https://support.crowdin.com/api/status/>

```ruby
crowdin.translations_status
```

### Project Info

Shows project details and meta information (last translations date, currently uploaded files, target languages etc..).

Documentation: <https://support.crowdin.com/api/info/>

```ruby
crowdin.project_info
```

### Export File

Export a single translated file from Crowdin.

Documentation: <https://support.crowdin.com/api/export-file/>

### Export Translations

Build ZIP archive with the latest translations.

**Note!** This method can be invoked only once per 30 minutes (there is no such restriction for organization plans).

Also API call will be ignored if there were no changes in the project since previous export.
You can see whether ZIP archive with latest translations was actually build by status attribute (`built` or `skipped`) returned in response.

Optional params:

* `:branch` - a branch name (default: nil)

Documentation: <https://support.crowdin.com/api/export/>

```ruby
crowdin.export_translations
```

### Account Projects

Get Crowdin Project details.

**Important:** This API method requires `Account API Key`. This key can not be found on your profile pages.

Documentation: <https://support.crowdin.com/api/get-projects/>

```ruby
crowdin = Crowdin::API.new(account_key: ACCOUNT_KEY)
crowdin.get_projects(login = 'YourCrowdinAccount')
```

### Create Project

Create Crowdin project.

**Important:** This API method requires `Account API Key`. This key can not be found on your profile pages.

Documentation: <https://support.crowdin.com/api/create-project/>

### Edit Project

Documentation: <https://support.crowdin.com/api/edit-project/>

### Delete Project

Documentation: <https://support.crowdin.com/api/delete-project/>

### Download Glossary

Documentation: <https://support.crowdin.com/api/download-glossary/>

### Upload Glossary

Documentation: <https://support.crowdin.com/api/upload-glossary/>

### Download TM

Documentation: <https://support.crowdin.com/api/download-tm/>

### Upload TM

Documentation: <https://support.crowdin.com/api/upload-tm/>

### Supported Languages

Documentation: <https://support.crowdin.com/api/supported-languages/>

## Supported Rubies

Tested with the following Ruby versions:

* MRI 2.2.1
* JRuby 9.0.0.0

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License and Author

Author: Anton Maminov (anton.maminov@gmail.com)

Copyright: 2012-2019 [crowdin.com](https://crowdin.com/)

This library is distributed under the MIT license. Please see the LICENSE file.
