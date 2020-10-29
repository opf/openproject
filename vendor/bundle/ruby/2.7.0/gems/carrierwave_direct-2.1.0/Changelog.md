### 2.1.0

Features:
  * Refactor policies to seperate classes and add back the old policy for
    backwards compatibility.
  * Added `direct_fog_hash` method that can be used for returning json

Misc:
  * Removed deprecated `key` methods.
  * Removed deprecated `:with_path` option for `direct_fog_url`

### 2.0.0

Features:
  * [BREAKING CHANGE] Add support for Carrierwave 1.x. Drops support for Carrierwave < 1.0 (Kevin Reintjes @kreintjes).

Misc:
  * Dropped support for ruby 2.0 and 2.1, they have [reached their end of life](https://www.ruby-lang.org/en/news/2017/04/01/support-of-ruby-2-1-has-ended/)
  * Update Ruby and Rails versions for Travis so builds succeed once again (Kevin Reintjes @kreintjes)

### 1.1.0

Deprecations:
  * Calling `direct_fog_url` with `:with_path` is deprecated, please use `url` instead.

### 1.0.0

Features:
  * Upgraded signing algorithm to use [AWS V4 POST authentication](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-authentication-HTTPPOST.html). This is a breaking change if you are constructing your own upload forms or submitting your own POST requests. See the Sinatra section of the README for a summary of the new fields required in your V4 POST request. (Fran Worley @fran-worley)

### 0.0.17

Misc:
  * Pin carrierwave to 0.11

### 0.0.16

Bug Fixes:
  * Allow uploader columns to be named `file` (Diego Plentz @plentz and Moisés Viloria @mois3x)
  * `["starts-with", "$utf8", ""]` is not needed as condition (Rocco Galluzzo @byterussian)

Misc:
  * Dropped support for ruby 1.9, it has [reached its end of life](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/) 
  * Add 2.2.0 support to travis. 
  * Compatible with Capybara 2.7
  * Replaced fog dependency with fog-aws; significantly reduces gem footprint

### 0.0.15

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.14...v0.0.15)

Features:
  * Allow format validators to be used on update (Grey Baker @greysteil)
  * Add cache_dir to allowed paths (Grey Baker @greysteil)

Bug Fixes:
  * Use Carrierwave to generate URL's (Petrik de Heus @p8)

Misc:
  * README update (Samuel Reh @samuelreh)
  * Fix typo in README (Brandon Conway @brandoncc)
  * Fix specs for rspec 3 (Hanachin @hanachin)
  * Fix typo in nl.yml (Petrik de Heus @p8)
  * Add multiple rails versions support to travis (Petrik de Heus @p8)

### 0.0.14

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.13...v0.0.14)

Features:
 * Add ability to set content type in upload form (John Kamenik @jkamenik)
 * Dutch language support (Ariejan de Vroom @ariejan)

Bug Fixes:
  * Escape characters in filenames (@geeky-sh)
  * Use OpenSSL::Digest instead of OpenSSL::Digest::Digest (@dwiedenbruch)
  * Fix signature race condition by caching policy (Louis Simoneau @lsimoneau)
  * Fix multi-encoding issue when saving escaped filenames (Vincent Franco @vinniefranco)
  * Use mounted-on column name for uniqueness validation (Stephan Schubert @jazen)

Misc:
  * Improve readme documentation for success action status support (Rafael Macedo @rafaelmacedo)
  * Increase robutness of view rpsec matchers (@sony-phoenix-dev)
  * Add ruby 2.1.0 support to travis (Luciano Sousa @lucianosousa)

### 0.0.13

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.12...v0.0.13)

Features:
  * Add option to use success_action_status instead of success_action_redirect (Nick DeLuca @nddeluca)

Bug Fixes:
 * Remove intial slash when generating key from url in order to fix updates (Enrique García @kikito)
 * Fix key generation when #default_url is overriden (@dunghuynh)
 * Fix policy glitch that allows other files to be overwritten (@dunghuynh)

Misc:
 * Update resque url in readme (Ever Daniel Barreto @everdaniel)
 * update readme (Philip Arndt @parndt)


### 0.0.12

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.11...v0.0.12)

Features:
  * use uuidtools gem instead of uuid gem for uid generation (Filip Tepper @filiptepper)

Bug Fixes:
  * fix URI parsing issues with cetain filenames (Ricky Pai @rickypai)
  * prevent double slashes in urls generated from direct_fog_url (Colin Young @colinyoung)

Misc:
 * fix typo in readme (@hartator)

### 0.0.11

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.10...v0.0.11)

### 0.0.10

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.9...v0.0.10)

### 0.0.9

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.8...v0.0.9)

### 0.0.8

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.7...v0.0.8)

### 0.0.7

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.6...v0.0.7)

### 0.0.6

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.5...v0.0.6)

### 0.0.5

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.4...v0.0.5)

### 0.0.4

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.3...v0.0.4)

### 0.0.3

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.2...v0.0.3)

### 0.0.2

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.1...v0.0.2)

### 0.0.1

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/e68498587a4e4209d121512dbb0df529e15e9282...v0.0.1)
