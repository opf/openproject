## unreleased 


### Changed

- A meaningful error is raised when the extension is included more than once (issue #89 fixed via #94) (@landongrindheim)
- Evaluate setting input immediately when input is provided. This allows for earlier feedback from constructors designed to raise errors on invalid input (#95) (@timriley)

[Compare v0.11.5...master](https://github.com/dry-rb/dry-configurable/compare/v0.11.5...master)

## 0.11.5 2020-03-23


### Fixed

- When settings are copied or cloned, unevaluated values will no longer be copied. This prevents unintended crashes when settings have constructors expecting a certain type of value, but that value is yet to be provided (Fixed via #87) (@timriley)

### Changed

- A meaningful error is raised when the extension is included more than once (issue #89 fixed via #94) (@landongrindheim)

[Compare v0.11.4...v0.11.5](https://github.com/dry-rb/dry-configurable/compare/v0.11.4...v0.11.5)

## 0.11.4 2020-03-16


### Fixed

- `Config#update` returns `self` again (issue #60 fixed via #92) (@solnic)

### Changed

- `Setting#inspect` no longer uses its value - this could cause crashes when inspecting settings that are yet to have a value applied (e.g. when they have a constructor that expects a value to be present) (@timriley)

[Compare v0.11.3...v0.11.4](https://github.com/dry-rb/dry-configurable/compare/v0.11.3...v0.11.4)

## 0.11.3 2020-02-22


### Fixed

- Retrieving settings by a string name works again (issue #82) (@waiting-for-dev)


[Compare v0.11.2...v0.11.3](https://github.com/dry-rb/dry-configurable/compare/v0.11.2...v0.11.3)

## 0.11.2 2020-02-20


### Fixed

- Warning about redefined `Setting#value` is gone (@solnic)


[Compare v0.11.1...v0.11.2](https://github.com/dry-rb/dry-configurable/compare/v0.11.1...v0.11.2)

## 0.11.1 2020-02-18


### Fixed

- You can use `:settings` as a config key again (issue #80) (@solnic)
- Setting value is lazy-evaluated now, which fixes some cases where a constructor could crash with a `nil` value (@solnic)


[Compare v0.11.0...v0.11.1](https://github.com/dry-rb/dry-configurable/compare/v0.11.0...v0.11.1)

## 0.11.0 2020-02-15

Complete rewrite of the library while keeping the public API intact. See #78 for a detailed overview.

### Changed

- Accessing config in a parent class no longer prevents you from adding more settings in a child class (@solnic)
- (internal) New low-level Setting and Config API (@solnic)
- (internal) `config` objects use method_missing now (@solnic)

[Compare v0.10.0...v0.11.0](https://github.com/dry-rb/dry-configurable/compare/v0.10.0...v0.11.0)

## 0.10.0 2020-01-31

YANKED because the change also broke inheritance for classes that used `configured` before other classes inherited from them.

### Changed

- Inheriting settings no longer defines the config object. This change fixed a use case where parent class that already used its config would prevent a child class from adding new settings (@solnic)

[Compare v0.9.0...v0.10.0](https://github.com/dry-rb/dry-configurable/compare/v0.9.0...v0.10.0)

## 0.9.0 2019-11-06


### Fixed

- Support for reserved names in settings. Some Kernel methods (`public_send` and `class` specifically) are not available if you use access settings via method call. Same for methods of the `Config` class. You can still access them with `[]` and `[]=`. Ruby keywords are fully supported. Invalid names containing special symbols (including `!` and `?`) are rejected. Note that these changes don't affect the `reader` option, if you define a setting named `:class` and pass `reader: true` ... well ... (flash-gordon)
- Settings can be redefined in subclasses without a warning about overriding exsting methods (flash-gordon)
- Fix warnings about using keyword arguments in 2.7 (koic)


[Compare v0.8.3...v0.9.0](https://github.com/dry-rb/dry-configurable/compare/v0.8.3...v0.9.0)

## 0.8.3 2019-05-29


### Fixed

- `Configurable#dup` and `Configurable#clone` make a copy of instance-level config so that it doesn't get mutated/shared across instances (flash-gordon)


[Compare v0.8.2...v0.8.3](https://github.com/dry-rb/dry-configurable/compare/v0.8.2...v0.8.3)

## 0.8.2 2019-02-25


### Fixed

- Test interface support for modules ([Neznauy](https://github.com/Neznauy))


[Compare v0.8.1...v0.8.2](https://github.com/dry-rb/dry-configurable/compare/v0.8.1...v0.8.2)

## 0.8.1 2019-02-06


### Fixed

- `.configure` doesn't require a block, this makes the behavior consistent with the previous versions ([flash-gordon](https://github.com/flash-gordon))


[Compare v0.8.0...v0.8.1](https://github.com/dry-rb/dry-configurable/compare/v0.8.0...v0.8.1)

## 0.8.0 2019-02-05


### Added

- Support for instance-level configuration landed. For usage, `include` the module instead of extending ([flash-gordon](https://github.com/flash-gordon))

  ```ruby
  class App
    include Dry::Configurable

    setting :database
  end

  production = App.new
  production.config.database = ENV['DATABASE_URL']
  production.finalize!

  development = App.new
  development.config.database = 'jdbc:sqlite:memory'
  development.finalize!
  ```
- Config values can be set from a hash with `.update`. Nested settings are supported ([flash-gordon](https://github.com/flash-gordon))

  ```ruby
  class App
    extend Dry::Configurable

    setting :db do
      setting :host
      setting :port
    end

    config.update(YAML.load(File.read("config.yml")))
  end
  ```

### Fixed

- A number of bugs related to inheriting settings from parent class were fixed. Ideally, new behavior will be :100: predictable but if you observe any anomaly, please report ([flash-gordon](https://github.com/flash-gordon))

### Changed

- [BREAKING] Minimal supported Ruby version is set to 2.3 ([flash-gordon](https://github.com/flash-gordon))

[Compare v0.7.0...v0.8.0](https://github.com/dry-rb/dry-configurable/compare/v0.7.0...v0.8.0)

## 0.7.0 2017-04-25


### Added

- Introduce `Configurable.finalize!` which freezes config and its dependencies ([qcam](https://github.com/qcam))

### Fixed

- Allow for boolean false as default setting value ([yuszuv](https://github.com/yuszuv))
- Convert nested configs to nested hashes with `Config#to_h` ([saverio-kantox](https://github.com/saverio-kantox))
- Disallow modification on frozen config ([qcam](https://github.com/qcam))
