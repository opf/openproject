# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## v1.0.2 - 2020-09-14

### Fixed
- Get foreign key from reflections when possible [\#383](https://github.com/brendon/acts_as_list/pull/383) ([jefftsang])

### Removed
- gemspec: Drop defunct `rubyforge_project` directive [\#373](https://github.com/brendon/acts_as_list/pull/373) ([olleolleolle])

[olleolleolle]: https://github.com/olleolleolle
[jefftsang]: https://github.com/jefftsang

## v1.0.1 - 2020-02-27

### Fixed
- Invert order when incrementing to circumvent unique index violations (#368)

## [v1.0.0](https://github.com/swanandp/acts_as_list/tree/v1.0.0) - 2019-09-26
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.9.19...v1.0.0)
### Removed
- **BREAKING CHANGE**: Support for Rails 3.2 > 4.1 has been removed. 0.9.19 is the last version that supports
	these Rails versions

### Added
- Added *Troubleshooting Database Deadlock Errors* section to `README.md`
- Added support for Rails 6.0 in testing
- Various README fixes
- A new method called `current_position` now exists and returns the integer position of the item it's
	called on, or `nil` if the position isn't set.

## [v0.9.19](https://github.com/swanandp/acts_as_list/tree/v0.9.19) - 2019-03-12
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.9.18...v0.9.19)
### Added
- Allow `acts_as_list_no_update` blocks to be nested [@conorbdaly](https://github.com/conorbdaly)

## [v0.9.18](https://github.com/swanandp/acts_as_list/tree/v0.9.18) - 2019-03-08
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.9.17...v0.9.18)

### Added
- Added additional gemspec metadata [@boone](https://github.com/boone)
- Add gem version badge to README [@joshuapinter](https://github.com/joshuapinter)
- Add touch on update configuration [@mgbatchelor](https://github.com/mgbatchelor)

### Changed
- Let's start a new direction with the CHANGELOG file [@mainameiz](https://github.com/mainameiz)

### Fixed
- Fix sqlite3 gem pinning breaking tests

## [v0.9.17](https://github.com/brendon/acts_as_list/tree/v0.9.17) (2018-10-29)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.16...v0.9.17)

**Closed issues:**

- Inconsistent behavior [\#330](https://github.com/brendon/acts_as_list/issues/330)
- Using `top\_of\_list` set to 1 and setting a record to index 0 triggers a `PG::UniqueViolation` [\#322](https://github.com/brendon/acts_as_list/issues/322)

**Merged pull requests:**

- Feature/add exception to wrong position [\#323](https://github.com/brendon/acts_as_list/pull/323) ([TheNeikos](https://github.com/TheNeikos))
- Methods move\_to\_bottom and move\_to\_top should not fail when there are unique constraints [\#320](https://github.com/brendon/acts_as_list/pull/320) ([faucct](https://github.com/faucct))

## [v0.9.16](https://github.com/brendon/acts_as_list/tree/v0.9.16) (2018-08-30)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.15...v0.9.16)

**Closed issues:**

- Re-ordering at specific position [\#318](https://github.com/brendon/acts_as_list/issues/318)
- `no\_update` is not applied to subclasses [\#314](https://github.com/brendon/acts_as_list/issues/314)
- NoMethodError: undefined method `acts\_as\_list' [\#303](https://github.com/brendon/acts_as_list/issues/303)
- Cannot create item at position 0 [\#297](https://github.com/brendon/acts_as_list/issues/297)

**Merged pull requests:**

- Unscope `select` to avoid PG::UndefinedFunction [\#283](https://github.com/brendon/acts_as_list/pull/283) ([donv](https://github.com/donv))

## [v0.9.15](https://github.com/brendon/acts_as_list/tree/v0.9.15) (2018-06-11)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.14...v0.9.15)

**Merged pull requests:**

- Fix \#314: `no\_update` is not applied to subclasses [\#315](https://github.com/brendon/acts_as_list/pull/315) ([YoranBrondsema](https://github.com/YoranBrondsema))

## [v0.9.14](https://github.com/brendon/acts_as_list/tree/v0.9.14) (2018-06-05)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.13...v0.9.14)

**Closed issues:**

- `insert\_at` saves invalid ActiveRecord objects [\#311](https://github.com/brendon/acts_as_list/issues/311)

**Merged pull requests:**

- \#311 Don't insert invalid ActiveRecord objects [\#312](https://github.com/brendon/acts_as_list/pull/312) ([seanabrahams](https://github.com/seanabrahams))

## [v0.9.13](https://github.com/brendon/acts_as_list/tree/v0.9.13) (2018-06-05)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.12...v0.9.13)

**Merged pull requests:**

- Fix unique index constraint failure on item destroy [\#313](https://github.com/brendon/acts_as_list/pull/313) ([yjukaku](https://github.com/yjukaku))

## [v0.9.12](https://github.com/brendon/acts_as_list/tree/v0.9.12) (2018-05-02)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.11...v0.9.12)

**Closed issues:**

- acts\_as\_list methods on has\_many through [\#308](https://github.com/brendon/acts_as_list/issues/308)
- Travis badge [\#307](https://github.com/brendon/acts_as_list/issues/307)
- Unscoping breaks STI subclasses, but is soon to be fixed in Rails [\#291](https://github.com/brendon/acts_as_list/issues/291)
- Refactor string eval for scope\_condition [\#227](https://github.com/brendon/acts_as_list/issues/227)

**Merged pull requests:**

- mocha/minitest, not mocha/mini\_test now. [\#310](https://github.com/brendon/acts_as_list/pull/310) ([jmarkbrooks](https://github.com/jmarkbrooks))

## [v0.9.11](https://github.com/brendon/acts_as_list/tree/v0.9.11) (2018-03-19)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.10...v0.9.11)

**Closed issues:**

- Setting `position: nil` on update returns `Column 'position' cannot be null` instead of putting the item at the start or the end of the list, like it does on create. [\#302](https://github.com/brendon/acts_as_list/issues/302)
- Switching to Semaphore [\#301](https://github.com/brendon/acts_as_list/issues/301)
- Dropping jruby support [\#300](https://github.com/brendon/acts_as_list/issues/300)
- Rails 5.2.0 [\#299](https://github.com/brendon/acts_as_list/issues/299)
- Cannot update record position when scoped to enum [\#298](https://github.com/brendon/acts_as_list/issues/298)
- `add\_new\_at: :top` does not work [\#296](https://github.com/brendon/acts_as_list/issues/296)
- remove\_from\_list causing "wrong number of arguments \(given 2, expected 0..1\)" [\#293](https://github.com/brendon/acts_as_list/issues/293)
- Passing raw strings to reorder deprecated in Rails 5.2 [\#290](https://github.com/brendon/acts_as_list/issues/290)

**Merged pull requests:**

- Fix Test Suite [\#306](https://github.com/brendon/acts_as_list/pull/306) ([brendon](https://github.com/brendon))
- Add frozen\_string\_literal pragma to ruby files [\#305](https://github.com/brendon/acts_as_list/pull/305) ([krzysiek1507](https://github.com/krzysiek1507))
- Use symbols instead of SQL strings for reorder \(for Rails 5.2\) [\#294](https://github.com/brendon/acts_as_list/pull/294) ([jhawthorn](https://github.com/jhawthorn))

## [v0.9.10](https://github.com/brendon/acts_as_list/tree/v0.9.10) (2017-11-19)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.9...v0.9.10)

**Closed issues:**

- Make insert\_at respect position when creating a new record [\#287](https://github.com/brendon/acts_as_list/issues/287)
- Why does acts\_as\_list override rails validation on it's own field? [\#269](https://github.com/brendon/acts_as_list/issues/269)

**Merged pull requests:**

- Change error classes parents [\#288](https://github.com/brendon/acts_as_list/pull/288) ([alexander-lazarov](https://github.com/alexander-lazarov))

## [v0.9.9](https://github.com/brendon/acts_as_list/tree/v0.9.9) (2017-10-03)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.8...v0.9.9)

**Merged pull requests:**

- Added fixed values option for scope array [\#286](https://github.com/brendon/acts_as_list/pull/286) ([smoyth](https://github.com/smoyth))

## [v0.9.8](https://github.com/brendon/acts_as_list/tree/v0.9.8) (2017-09-28)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.7...v0.9.8)

**Closed issues:**

- Deadlocking in update\_positions count query [\#285](https://github.com/brendon/acts_as_list/issues/285)
- Updating the position fails uniqueness constraint. [\#275](https://github.com/brendon/acts_as_list/issues/275)

## [v0.9.7](https://github.com/brendon/acts_as_list/tree/v0.9.7) (2017-07-06)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.6...v0.9.7)

## [v0.9.6](https://github.com/brendon/acts_as_list/tree/v0.9.6) (2017-07-05)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.5...v0.9.6)

**Closed issues:**

- undefined method `+' for nil:NilClass [\#278](https://github.com/brendon/acts_as_list/issues/278)
- Enum does not scope correctly [\#277](https://github.com/brendon/acts_as_list/issues/277)
- Can we don't use remove\_from\_list when destroy a lot objects? [\#276](https://github.com/brendon/acts_as_list/issues/276)
- The NoUpdate code rely's on AS::Concern [\#273](https://github.com/brendon/acts_as_list/issues/273)
- ActiveRecord associations are no longer required \(even though belongs\_to\_required\_by\_default == true\) [\#268](https://github.com/brendon/acts_as_list/issues/268)
- Unique constraint violation on move\_higher, move\_lower, destroy [\#267](https://github.com/brendon/acts_as_list/issues/267)

**Merged pull requests:**

- Fix Fixnum deprecation warnings. [\#282](https://github.com/brendon/acts_as_list/pull/282) ([patrickdavey](https://github.com/patrickdavey))
- Fix update to scope that was defined with an enum [\#281](https://github.com/brendon/acts_as_list/pull/281) ([scottmalone](https://github.com/scottmalone))
- Refactor update\_all\_with\_touch [\#279](https://github.com/brendon/acts_as_list/pull/279) ([ledestin](https://github.com/ledestin))
- Remove AS::Concern from NoUpdate [\#274](https://github.com/brendon/acts_as_list/pull/274) ([brendon](https://github.com/brendon))
- Use `ActiveSupport.on\_load` to hook into ActiveRecord [\#272](https://github.com/brendon/acts_as_list/pull/272) ([brendon](https://github.com/brendon))

## [v0.9.5](https://github.com/brendon/acts_as_list/tree/v0.9.5) (2017-04-04)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.4...v0.9.5)

**Closed issues:**

- acts\_as\_list\_class.maximum\(position\_column\) is causing the entire table to lock [\#264](https://github.com/brendon/acts_as_list/issues/264)
- Be more precise with unscope-ing [\#263](https://github.com/brendon/acts_as_list/issues/263)

**Merged pull requests:**

- Use bottom\_position\_in\_list instead of the highest value in the table [\#266](https://github.com/brendon/acts_as_list/pull/266) ([brendon](https://github.com/brendon))
- Be more surgical about unscoping [\#265](https://github.com/brendon/acts_as_list/pull/265) ([brendon](https://github.com/brendon))

## [v0.9.4](https://github.com/brendon/acts_as_list/tree/v0.9.4) (2017-03-16)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.3...v0.9.4)

**Merged pull requests:**

- Optimize first? and last? instance methods. [\#262](https://github.com/brendon/acts_as_list/pull/262) ([marshall-lee](https://github.com/marshall-lee))

## [v0.9.3](https://github.com/brendon/acts_as_list/tree/v0.9.3) (2017-03-14)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.2...v0.9.3)

**Closed issues:**

- Rails 5.1.0.beta1 deprecation [\#257](https://github.com/brendon/acts_as_list/issues/257)
- Move item X after item Y [\#256](https://github.com/brendon/acts_as_list/issues/256)
- Is there way to specify the position when creating a resource? [\#255](https://github.com/brendon/acts_as_list/issues/255)

**Merged pull requests:**

- Don't update a child destroyed via relation [\#261](https://github.com/brendon/acts_as_list/pull/261) ([brendon](https://github.com/brendon))
- No update list for collection classes [\#260](https://github.com/brendon/acts_as_list/pull/260) ([IlkhamGaysin](https://github.com/IlkhamGaysin))
- Fix deprecation introduced in ActiveRecord 5.1.0.beta1. Closes \#257 [\#259](https://github.com/brendon/acts_as_list/pull/259) ([CvX](https://github.com/CvX))
- Refactor column definer module [\#258](https://github.com/brendon/acts_as_list/pull/258) ([ledestin](https://github.com/ledestin))

## [v0.9.2](https://github.com/brendon/acts_as_list/tree/v0.9.2) (2017-02-07)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.1...v0.9.2)

**Closed issues:**

- Getting invalid input syntax for uuid [\#253](https://github.com/brendon/acts_as_list/issues/253)

## [v0.9.1](https://github.com/brendon/acts_as_list/tree/v0.9.1) (2017-01-26)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.9.0...v0.9.1)

**Closed issues:**

- DEPRECATION WARNING on rails 5.0 as of acts\_as\_list 0.9 [\#251](https://github.com/brendon/acts_as_list/issues/251)
- highter\_items returns items with the same position value [\#247](https://github.com/brendon/acts_as_list/issues/247)
- Broken with unique constraint on position [\#245](https://github.com/brendon/acts_as_list/issues/245)

**Merged pull requests:**

- fixes \#251 table\_exists? deprecation warning with Rails 5.0 [\#252](https://github.com/brendon/acts_as_list/pull/252) ([zharikovpro](https://github.com/zharikovpro))

## [v0.9.0](https://github.com/brendon/acts_as_list/tree/v0.9.0) (2017-01-23)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.8.2...v0.9.0)

**Closed issues:**

- warning: too many arguments for format string [\#239](https://github.com/brendon/acts_as_list/issues/239)
- Broken tests related to time comparison [\#238](https://github.com/brendon/acts_as_list/issues/238)
- Shuffling positions is halting the callback chain [\#234](https://github.com/brendon/acts_as_list/issues/234)
- Reorder positions [\#233](https://github.com/brendon/acts_as_list/issues/233)
- Tests break when upgrading from 0.7.2 to 0.7.4 [\#228](https://github.com/brendon/acts_as_list/issues/228)
- RE \#221 needing a test [\#226](https://github.com/brendon/acts_as_list/issues/226)
- Adding to existing model with data and methods don't work [\#209](https://github.com/brendon/acts_as_list/issues/209)
- Position is set incorrectly when circular dependencies exist [\#153](https://github.com/brendon/acts_as_list/issues/153)

**Merged pull requests:**

- Revert "Updates documentation with valid string interpolation syntax" [\#250](https://github.com/brendon/acts_as_list/pull/250) ([brendon](https://github.com/brendon))
- Updates documentation with valid string interpolation syntax [\#249](https://github.com/brendon/acts_as_list/pull/249) ([naveedkakal](https://github.com/naveedkakal))
- Comply to tests warnings [\#248](https://github.com/brendon/acts_as_list/pull/248) ([randoum](https://github.com/randoum))
- insert\_at respects unique not null check \(\>= 0\) db constraints [\#246](https://github.com/brendon/acts_as_list/pull/246) ([zharikovpro](https://github.com/zharikovpro))
- acts\_as\_list\_no\_update [\#244](https://github.com/brendon/acts_as_list/pull/244) ([randoum](https://github.com/randoum))
- Update README.md [\#243](https://github.com/brendon/acts_as_list/pull/243) ([rahuldstiwari](https://github.com/rahuldstiwari))
- Fixed tests to prevent warning: too many arguments for format string [\#242](https://github.com/brendon/acts_as_list/pull/242) ([brendon](https://github.com/brendon))
- Be explicit about ordering when mapping :pos [\#241](https://github.com/brendon/acts_as_list/pull/241) ([brendon](https://github.com/brendon))
- Improve load method [\#240](https://github.com/brendon/acts_as_list/pull/240) ([brendon](https://github.com/brendon))
- Fix non regular sequence movement [\#237](https://github.com/brendon/acts_as_list/pull/237) ([tiagotex](https://github.com/tiagotex))
- Add travis config for testing against multiple databases [\#236](https://github.com/brendon/acts_as_list/pull/236) ([fschwahn](https://github.com/fschwahn))
- Extract modules [\#229](https://github.com/brendon/acts_as_list/pull/229) ([ledestin](https://github.com/ledestin))

## [v0.8.2](https://github.com/brendon/acts_as_list/tree/v0.8.2) (2016-09-23)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.8.1...v0.8.2)

**Closed issues:**

- We're a repo now, no longer a fork attached to rails/acts\_as\_list [\#232](https://github.com/brendon/acts_as_list/issues/232)
- Break away from rails/acts\_as\_list [\#224](https://github.com/brendon/acts_as_list/issues/224)
- Problem when inserting straight at top of list [\#109](https://github.com/brendon/acts_as_list/issues/109)

**Merged pull requests:**

- Show items with same position in higher and lower items [\#231](https://github.com/brendon/acts_as_list/pull/231) ([jpalumickas](https://github.com/jpalumickas))
- fix setting position when previous position was nil [\#230](https://github.com/brendon/acts_as_list/pull/230) ([StoneFrog](https://github.com/StoneFrog))

## [v0.8.1](https://github.com/brendon/acts_as_list/tree/v0.8.1) (2016-09-06)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.8.0...v0.8.1)

**Closed issues:**

- Rubinius Intermittent testing error [\#218](https://github.com/brendon/acts_as_list/issues/218)
- ActiveRecord dependency causes rake assets:compile to fail without access to a database [\#84](https://github.com/brendon/acts_as_list/issues/84)

**Merged pull requests:**

- Refactor class\_eval with string into class\_eval with block [\#215](https://github.com/brendon/acts_as_list/pull/215) ([rdvdijk](https://github.com/rdvdijk))

## [v0.8.0](https://github.com/brendon/acts_as_list/tree/v0.8.0) (2016-08-23)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.7...v0.8.0)

**Closed issues:**

- Behavior with DB default seems unclear [\#219](https://github.com/brendon/acts_as_list/issues/219)

**Merged pull requests:**

- No longer a need specify additional rbx gems [\#225](https://github.com/brendon/acts_as_list/pull/225) ([brendon](https://github.com/brendon))
- Fix position when no serial positions [\#223](https://github.com/brendon/acts_as_list/pull/223) ([jpalumickas](https://github.com/jpalumickas))
- Bug: Specifying a position with add\_new\_at: :top fails to insert at that position [\#220](https://github.com/brendon/acts_as_list/pull/220) ([brendon](https://github.com/brendon))

## [v0.7.7](https://github.com/brendon/acts_as_list/tree/v0.7.7) (2016-08-18)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.6...v0.7.7)

**Closed issues:**

- Issue after upgrading to 0.7.5: No connection pool with id primary found. [\#214](https://github.com/brendon/acts_as_list/issues/214)
- Changing scope is inconsistent based on add\_new\_at [\#138](https://github.com/brendon/acts_as_list/issues/138)
- Duplicate positions and lost items [\#76](https://github.com/brendon/acts_as_list/issues/76)

**Merged pull requests:**

- Add quoted table names to some columns [\#221](https://github.com/brendon/acts_as_list/pull/221) ([jpalumickas](https://github.com/jpalumickas))
- Appraisals cleanup [\#217](https://github.com/brendon/acts_as_list/pull/217) ([brendon](https://github.com/brendon))
- Fix insert\_at\_position in race condition [\#195](https://github.com/brendon/acts_as_list/pull/195) ([danielross](https://github.com/danielross))

## [v0.7.6](https://github.com/brendon/acts_as_list/tree/v0.7.6) (2016-07-15)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.5...v0.7.6)

**Closed issues:**

- add\_new\_at nil with scope causes NoMethodError [\#211](https://github.com/brendon/acts_as_list/issues/211)

**Merged pull requests:**

- Add class method acts\_as\_list\_top as reader for configured top\_of\_list [\#213](https://github.com/brendon/acts_as_list/pull/213) ([krzysiek1507](https://github.com/krzysiek1507))
- Bugfix/add new at nil on scope change [\#212](https://github.com/brendon/acts_as_list/pull/212) ([greatghoul](https://github.com/greatghoul))

## [v0.7.5](https://github.com/brendon/acts_as_list/tree/v0.7.5) (2016-06-30)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.4...v0.7.5)

**Implemented enhancements:**

- Touch when reordering [\#173](https://github.com/brendon/acts_as_list/pull/173) ([botandrose](https://github.com/botandrose))

**Closed issues:**

- Exception raised when calling destroy "NameError - instance variable @scope\_changed not defined:" [\#206](https://github.com/brendon/acts_as_list/issues/206)
- Undefined instance variable @scope\_changed since 0.7.3 [\#199](https://github.com/brendon/acts_as_list/issues/199)
- Reordering large lists is slow [\#198](https://github.com/brendon/acts_as_list/issues/198)
- Reparenting child leaves gap in source list in rails 5 [\#194](https://github.com/brendon/acts_as_list/issues/194)
- Support rails 5 ? [\#186](https://github.com/brendon/acts_as_list/issues/186)
- I get a NoMethodError: undefined method `acts\_as\_list' when trying to include acts\_as\_list [\#176](https://github.com/brendon/acts_as_list/issues/176)
- Phenomenon of mysterious value of the position is skipped by one [\#166](https://github.com/brendon/acts_as_list/issues/166)
- Model.find being called twice with acts\_as\_list on destroy [\#161](https://github.com/brendon/acts_as_list/issues/161)
- `scope\_changed?` problem with acts\_as\_paranoid [\#158](https://github.com/brendon/acts_as_list/issues/158)
- Inconsistent behaviour between Symbol and Array scopes [\#155](https://github.com/brendon/acts_as_list/issues/155)
- insert\_at doesn't seem to be working in ActiveRecord callback \(Rails 4.2\) [\#150](https://github.com/brendon/acts_as_list/issues/150)
- Project Documentation link redirects to expired domain [\#149](https://github.com/brendon/acts_as_list/issues/149)
- Problem when updating an position of array of AR objects. [\#137](https://github.com/brendon/acts_as_list/issues/137)
- Unexpected behaviour when inserting consecutive items with default positions [\#124](https://github.com/brendon/acts_as_list/issues/124)
- self.reload prone to error [\#122](https://github.com/brendon/acts_as_list/issues/122)
- Rails 3.0.x in\_list causes the return of default\_scope [\#120](https://github.com/brendon/acts_as_list/issues/120)
- Relationships with dependency:destroy cause ActiveRecord::RecordNotFound [\#118](https://github.com/brendon/acts_as_list/issues/118)
- Using insert\_at with values with type String [\#117](https://github.com/brendon/acts_as_list/issues/117)
- Batch setting of position [\#112](https://github.com/brendon/acts_as_list/issues/112)
- position: 0 now makes model pushed to top? [\#110](https://github.com/brendon/acts_as_list/issues/110)
- Create element in default position [\#103](https://github.com/brendon/acts_as_list/issues/103)
- Enhancement: Expose scope object [\#97](https://github.com/brendon/acts_as_list/issues/97)
- Shuffle list [\#96](https://github.com/brendon/acts_as_list/issues/96)
- Creating an item with a nil scope should not add it to the list [\#92](https://github.com/brendon/acts_as_list/issues/92)
- Performance Improvements  [\#88](https://github.com/brendon/acts_as_list/issues/88)
- has\_many :through or has\_many\_and\_belongs\_to\_many support [\#86](https://github.com/brendon/acts_as_list/issues/86)
- move\_higher/move\_lower vs move\_to\_top/move\_to\_bottom act differently when item is already at top or bottom [\#77](https://github.com/brendon/acts_as_list/issues/77)
- Limiting the list size [\#61](https://github.com/brendon/acts_as_list/issues/61)
- Adding multiple creates strange ordering [\#55](https://github.com/brendon/acts_as_list/issues/55)
- Feature: sort [\#26](https://github.com/brendon/acts_as_list/issues/26)

**Merged pull requests:**

- Fix position when no serial positions [\#208](https://github.com/brendon/acts_as_list/pull/208) ([PoslinskiNet](https://github.com/PoslinskiNet))
- Removed duplicated assignment [\#207](https://github.com/brendon/acts_as_list/pull/207) ([shunwen](https://github.com/shunwen))
- Quote all identifiers [\#205](https://github.com/brendon/acts_as_list/pull/205) ([fabn](https://github.com/fabn))
- Start testing Rails 5 [\#203](https://github.com/brendon/acts_as_list/pull/203) ([brendon](https://github.com/brendon))
- Lock! the record before destroying [\#201](https://github.com/brendon/acts_as_list/pull/201) ([brendon](https://github.com/brendon))
- Fix ambiguous column error when joining some relations [\#180](https://github.com/brendon/acts_as_list/pull/180) ([natw](https://github.com/natw))

## [v0.7.4](https://github.com/brendon/acts_as_list/tree/v0.7.4) (2016-04-15)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.3...v0.7.4)

**Closed issues:**

- Releasing a new gem version [\#196](https://github.com/brendon/acts_as_list/issues/196)

**Merged pull requests:**

- Fix scope changed [\#200](https://github.com/brendon/acts_as_list/pull/200) ([brendon](https://github.com/brendon))

## [v0.7.3](https://github.com/brendon/acts_as_list/tree/v0.7.3) (2016-04-14)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/v0.7.2...v0.7.3)

## [v0.7.2](https://github.com/brendon/acts_as_list/tree/v0.7.2) (2016-04-01)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.7.2...v0.7.2)

**Closed issues:**

- DEPRECATION WARNING: Passing string to define callback on Rails 5 beta 3 [\#191](https://github.com/brendon/acts_as_list/issues/191)
- Why is `add\_to\_list\_bottom` private? [\#187](https://github.com/brendon/acts_as_list/issues/187)
- Ordering of children when there are two possible parent models. [\#172](https://github.com/brendon/acts_as_list/issues/172)
- Fix the jruby and rbx builds [\#169](https://github.com/brendon/acts_as_list/issues/169)
- Unable to run tests [\#162](https://github.com/brendon/acts_as_list/issues/162)
- shuffle\_positions\_on\_intermediate\_items is creating problems [\#134](https://github.com/brendon/acts_as_list/issues/134)
- introduce Changelog file to quickly track changes [\#68](https://github.com/brendon/acts_as_list/issues/68)
- Mongoid support? [\#52](https://github.com/brendon/acts_as_list/issues/52)

**Merged pull requests:**

- Add filename/line number to class\_eval call [\#193](https://github.com/brendon/acts_as_list/pull/193) ([hfwang](https://github.com/hfwang))
- Use a symbol as a string to define callback [\#192](https://github.com/brendon/acts_as_list/pull/192) ([brendon](https://github.com/brendon))
- Pin changelog generator to a working version [\#190](https://github.com/brendon/acts_as_list/pull/190) ([fabn](https://github.com/fabn))
- Fix bug, position is recomputed when object saved [\#188](https://github.com/brendon/acts_as_list/pull/188) ([chrisortman](https://github.com/chrisortman))
- Update bundler before running tests, fixes test run on travis [\#179](https://github.com/brendon/acts_as_list/pull/179) ([fabn](https://github.com/fabn))
- Changelog generator, closes \#68 [\#177](https://github.com/brendon/acts_as_list/pull/177) ([fabn](https://github.com/fabn))
- Updating README example [\#175](https://github.com/brendon/acts_as_list/pull/175) ([ryanbillings](https://github.com/ryanbillings))
- Adds description about various options available with the acts\_as\_list method [\#168](https://github.com/brendon/acts_as_list/pull/168) ([udit7590](https://github.com/udit7590))
- Small changes to DRY up list.rb [\#163](https://github.com/brendon/acts_as_list/pull/163) ([Albin-Willman](https://github.com/Albin-Willman))
- Only swap changed attributes which are persistable, i.e. are DB columns. [\#152](https://github.com/brendon/acts_as_list/pull/152) ([ludwigschubert](https://github.com/ludwigschubert))

## [0.7.2](https://github.com/brendon/acts_as_list/tree/0.7.2) (2015-05-06)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.7.1...0.7.2)

## [0.7.1](https://github.com/brendon/acts_as_list/tree/0.7.1) (2015-05-06)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.7.0...0.7.1)

**Merged pull requests:**

- Update README.md [\#159](https://github.com/brendon/acts_as_list/pull/159) ([tibastral](https://github.com/tibastral))

## [0.7.0](https://github.com/brendon/acts_as_list/tree/0.7.0) (2015-05-01)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.6.0...0.7.0)

**Closed issues:**

- Problem with reordering scoped list items [\#154](https://github.com/brendon/acts_as_list/issues/154)
- Can no longer load acts\_as\_list in isolation if Rails is installed [\#145](https://github.com/brendon/acts_as_list/issues/145)

**Merged pull requests:**

- Fix regression with using acts\_as\_list on base classes [\#147](https://github.com/brendon/acts_as_list/pull/147) ([botandrose](https://github.com/botandrose))
- Don't require rails when loading [\#146](https://github.com/brendon/acts_as_list/pull/146) ([botandrose](https://github.com/botandrose))

## [0.6.0](https://github.com/brendon/acts_as_list/tree/0.6.0) (2014-12-24)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.5.0...0.6.0)

**Closed issues:**

- Deprecation Warning: sanitize\_sql\_hash\_for\_conditions is deprecated and will be removed in Rails 5.0 [\#143](https://github.com/brendon/acts_as_list/issues/143)
- Release a new gem version [\#136](https://github.com/brendon/acts_as_list/issues/136)

**Merged pull requests:**

- Fix sanitize\_sql\_hash\_for\_conditions deprecation warning in Rails 4.2 [\#140](https://github.com/brendon/acts_as_list/pull/140) ([eagletmt](https://github.com/eagletmt))
- Simpler method to find the subclass name [\#139](https://github.com/brendon/acts_as_list/pull/139) ([brendon](https://github.com/brendon))
- Rails4 enum column support [\#130](https://github.com/brendon/acts_as_list/pull/130) ([arunagw](https://github.com/arunagw))
- use eval for determing the self.class.name useful when this is used in an abstract class [\#123](https://github.com/brendon/acts_as_list/pull/123) ([flarik](https://github.com/flarik))

## [0.5.0](https://github.com/brendon/acts_as_list/tree/0.5.0) (2014-10-31)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.4.0...0.5.0)

**Closed issues:**

- I want to have my existing records works like list [\#133](https://github.com/brendon/acts_as_list/issues/133)
- Add Support For Multiple Indexes [\#127](https://github.com/brendon/acts_as_list/issues/127)
- changing parent\_id does not update item positions [\#126](https://github.com/brendon/acts_as_list/issues/126)
- How to exclude objects to be positioned? [\#125](https://github.com/brendon/acts_as_list/issues/125)
- Scope for Polymorphic association + ManyToMany [\#106](https://github.com/brendon/acts_as_list/issues/106)
- Bug when use \#insert\_at on an invalid ActiveRecord object [\#99](https://github.com/brendon/acts_as_list/issues/99)
- has\_many :through with acts as list [\#95](https://github.com/brendon/acts_as_list/issues/95)
- Update position when scope changes [\#19](https://github.com/brendon/acts_as_list/issues/19)

**Merged pull requests:**

- Cast column default value to int before comparing with position column [\#129](https://github.com/brendon/acts_as_list/pull/129) ([wioux](https://github.com/wioux))
- Fix travis builds for rbx [\#128](https://github.com/brendon/acts_as_list/pull/128) ([meineerde](https://github.com/meineerde))
- Use unscoped blocks instead of chaining [\#121](https://github.com/brendon/acts_as_list/pull/121) ([brendon](https://github.com/brendon))
- Make acts\_as\_list more compatible with BINARY column [\#116](https://github.com/brendon/acts_as_list/pull/116) ([sikachu](https://github.com/sikachu))
- Added help notes on non-association scopes [\#115](https://github.com/brendon/acts_as_list/pull/115) ([VorontsovIE](https://github.com/VorontsovIE))
- Let AR::Base properly lazy-loaded if Railtie is available [\#114](https://github.com/brendon/acts_as_list/pull/114) ([amatsuda](https://github.com/amatsuda))

## [0.4.0](https://github.com/brendon/acts_as_list/tree/0.4.0) (2014-02-22)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.3.0...0.4.0)

**Closed issues:**

- insert\_at creates gaps [\#108](https://github.com/brendon/acts_as_list/issues/108)
- move\_lower and move\_higher not working returning nil [\#57](https://github.com/brendon/acts_as_list/issues/57)
- Mass-assignment issue with 0.1.8 [\#50](https://github.com/brendon/acts_as_list/issues/50)
- validates error [\#49](https://github.com/brendon/acts_as_list/issues/49)
- Ability to move multiple at once [\#40](https://github.com/brendon/acts_as_list/issues/40)
- Duplicates created when using accepts\_nested\_attributes\_for [\#29](https://github.com/brendon/acts_as_list/issues/29)

**Merged pull requests:**

- Update README [\#107](https://github.com/brendon/acts_as_list/pull/107) ([Senjai](https://github.com/Senjai))
- Add license info: license file and gemspec [\#105](https://github.com/brendon/acts_as_list/pull/105) ([chulkilee](https://github.com/chulkilee))
- Fix top position when position is lower than top position [\#104](https://github.com/brendon/acts_as_list/pull/104) ([csaura](https://github.com/csaura))
- Get specs running under Rails 4.1.0.beta1 [\#101](https://github.com/brendon/acts_as_list/pull/101) ([petergoldstein](https://github.com/petergoldstein))
- Add support for JRuby and Rubinius specs [\#100](https://github.com/brendon/acts_as_list/pull/100) ([petergoldstein](https://github.com/petergoldstein))
- Use the correct syntax for conditions in Rails 4 on the readme. [\#94](https://github.com/brendon/acts_as_list/pull/94) ([gotjosh](https://github.com/gotjosh))
- Adds `required\_ruby\_version` to gemspec [\#90](https://github.com/brendon/acts_as_list/pull/90) ([tvdeyen](https://github.com/tvdeyen))

## [0.3.0](https://github.com/brendon/acts_as_list/tree/0.3.0) (2013-08-02)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.2.0...0.3.0)

**Closed issues:**

- act\_as\_list didn't install with bundle install [\#83](https://github.com/brendon/acts_as_list/issues/83)
- Cannot update to version 0.1.7 [\#48](https://github.com/brendon/acts_as_list/issues/48)
- when position is null all new items get inserted in position 1 [\#41](https://github.com/brendon/acts_as_list/issues/41)

**Merged pull requests:**

- Test against activerecord v3 and v4 [\#82](https://github.com/brendon/acts_as_list/pull/82) ([sanemat](https://github.com/sanemat))
- Fix check\_scope to work on lists with array scopes [\#81](https://github.com/brendon/acts_as_list/pull/81) ([conzett](https://github.com/conzett))
- Rails4 compatibility [\#80](https://github.com/brendon/acts_as_list/pull/80) ([philippfranke](https://github.com/philippfranke))
- Add tests for moving within scope and add method: move\_within\_scope [\#79](https://github.com/brendon/acts_as_list/pull/79) ([philippfranke](https://github.com/philippfranke))
- Option to not automatically add items to the list [\#72](https://github.com/brendon/acts_as_list/pull/72) ([forrest](https://github.com/forrest))

## [0.2.0](https://github.com/brendon/acts_as_list/tree/0.2.0) (2013-02-28)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.9...0.2.0)

**Merged pull requests:**

- Fix update\_all deprecation warnings in Rails 4.0.0.beta1 [\#73](https://github.com/brendon/acts_as_list/pull/73) ([soffes](https://github.com/soffes))
- Add quotes to Id in SQL requests [\#69](https://github.com/brendon/acts_as_list/pull/69) ([noefroidevaux](https://github.com/noefroidevaux))
- Update position when scope changes [\#67](https://github.com/brendon/acts_as_list/pull/67) ([philippfranke](https://github.com/philippfranke))
- add and categorize public instance methods in readme; add misc notes to ... [\#66](https://github.com/brendon/acts_as_list/pull/66) ([barelyknown](https://github.com/barelyknown))
- Updates \#bottom\_item .find syntax to \>= Rails 3 compatible syntax. [\#65](https://github.com/brendon/acts_as_list/pull/65) ([tvdeyen](https://github.com/tvdeyen))
- add GitHub Flavored Markdown to README [\#63](https://github.com/brendon/acts_as_list/pull/63) ([phlipper](https://github.com/phlipper))

## [0.1.9](https://github.com/brendon/acts_as_list/tree/0.1.9) (2012-12-04)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.8...0.1.9)

**Closed issues:**

- Mysql2 error [\#54](https://github.com/brendon/acts_as_list/issues/54)
- Use alternative column name? [\#53](https://github.com/brendon/acts_as_list/issues/53)

**Merged pull requests:**

- attr-accessible can be damaging, is not always necessary. [\#60](https://github.com/brendon/acts_as_list/pull/60) ([graemeworthy](https://github.com/graemeworthy))
- More reliable lower/higher item detection [\#59](https://github.com/brendon/acts_as_list/pull/59) ([miks](https://github.com/miks))
- Instructions for using an array with scope [\#58](https://github.com/brendon/acts_as_list/pull/58) ([zukowski](https://github.com/zukowski))
- Attr accessible patch, should solve \#50 [\#51](https://github.com/brendon/acts_as_list/pull/51) ([fabn](https://github.com/fabn))
- support accepts\_nested\_attributes\_for multi-destroy [\#46](https://github.com/brendon/acts_as_list/pull/46) ([saberma](https://github.com/saberma))

## [0.1.8](https://github.com/brendon/acts_as_list/tree/0.1.8) (2012-08-09)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.7...0.1.8)

## [0.1.7](https://github.com/brendon/acts_as_list/tree/0.1.7) (2012-08-09)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.6...0.1.7)

**Closed issues:**

- Remove use of update\_attribute [\#44](https://github.com/brendon/acts_as_list/issues/44)
- Order is reversed when adding multiple rows at once [\#34](https://github.com/brendon/acts_as_list/issues/34)

**Merged pull requests:**

- Fixed issue with update\_positions that wasn't taking 'scope\_condition' into account [\#47](https://github.com/brendon/acts_as_list/pull/47) ([bastien](https://github.com/bastien))
- Replaced usage of update\_attribute with update\_attribute!  [\#45](https://github.com/brendon/acts_as_list/pull/45) ([kevmoo](https://github.com/kevmoo))
- use self.class.primary\_key instead of id in shuffle\_positions\_on\_intermediate\_items [\#42](https://github.com/brendon/acts_as_list/pull/42) ([servercrunch](https://github.com/servercrunch))
- initialize gem [\#39](https://github.com/brendon/acts_as_list/pull/39) ([megatux](https://github.com/megatux))
- Added ability to set item positions directly \(e.g. In a form\) [\#38](https://github.com/brendon/acts_as_list/pull/38) ([dubroe](https://github.com/dubroe))
- Prevent SQL error when position\_column is not unique [\#37](https://github.com/brendon/acts_as_list/pull/37) ([hinrik](https://github.com/hinrik))
- Add installation instructions to README.md [\#35](https://github.com/brendon/acts_as_list/pull/35) ([mark-rushakoff](https://github.com/mark-rushakoff))

## [0.1.6](https://github.com/brendon/acts_as_list/tree/0.1.6) (2012-04-19)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.5...0.1.6)

**Closed issues:**

- eval mistakenly resolved the module path [\#32](https://github.com/brendon/acts_as_list/issues/32)
- Duplicated positions when creating parent and children from scratch in 0.1.5 [\#31](https://github.com/brendon/acts_as_list/issues/31)
- add info about v0.1.5 require Rails 3 [\#28](https://github.com/brendon/acts_as_list/issues/28)
- position not updated with move\_higher or move\_lover [\#23](https://github.com/brendon/acts_as_list/issues/23)

**Merged pull requests:**

- update ActiveRecord class eval to support ActiveSupport on\_load [\#33](https://github.com/brendon/acts_as_list/pull/33) ([mergulhao](https://github.com/mergulhao))
- Add :add\_new\_at option [\#30](https://github.com/brendon/acts_as_list/pull/30) ([mjbellantoni](https://github.com/mjbellantoni))

## [0.1.5](https://github.com/brendon/acts_as_list/tree/0.1.5) (2012-02-24)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.4...0.1.5)

**Closed issues:**

- increment\_positions\_on\_lower\_items called twice on insert\_at with new item [\#21](https://github.com/brendon/acts_as_list/issues/21)
- Change bundler dependency from ~\>1.0.0 to ~\>1.0 [\#20](https://github.com/brendon/acts_as_list/issues/20)
- decrement\_positions\_on\_lower\_items method [\#17](https://github.com/brendon/acts_as_list/issues/17)
- New gem release [\#16](https://github.com/brendon/acts_as_list/issues/16)
- acts\_as\_list :scope =\> "doesnt\_seem\_to\_work" [\#12](https://github.com/brendon/acts_as_list/issues/12)
- don't work perfectly with default\_scope [\#11](https://github.com/brendon/acts_as_list/issues/11)
- MySQL: Position column MUST NOT have default [\#10](https://github.com/brendon/acts_as_list/issues/10)
- insert\_at fails on postgresql w/ non-null constraint on postion\_column  [\#8](https://github.com/brendon/acts_as_list/issues/8)

**Merged pull requests:**

- Efficiency improvement for insert\_at when repositioning an existing item [\#27](https://github.com/brendon/acts_as_list/pull/27) ([bradediger](https://github.com/bradediger))
- Use before validate instead of before create [\#25](https://github.com/brendon/acts_as_list/pull/25) ([webervin](https://github.com/webervin))
- Massive test refactorings. [\#24](https://github.com/brendon/acts_as_list/pull/24) ([splattael](https://github.com/splattael))
- Silent migrations to reduce test noise. [\#22](https://github.com/brendon/acts_as_list/pull/22) ([splattael](https://github.com/splattael))
- Should decrement lower items after the item has been destroyed to avoid unique key conflicts. [\#18](https://github.com/brendon/acts_as_list/pull/18) ([aepstein](https://github.com/aepstein))
- Fix spelling and grammer [\#15](https://github.com/brendon/acts_as_list/pull/15) ([tmiller](https://github.com/tmiller))
- store\_at\_0 should yank item from the list then decrement items to avoid r [\#14](https://github.com/brendon/acts_as_list/pull/14) ([aepstein](https://github.com/aepstein))
- Support default\_scope ordering by calling .unscoped [\#13](https://github.com/brendon/acts_as_list/pull/13) ([tanordheim](https://github.com/tanordheim))

## [0.1.4](https://github.com/brendon/acts_as_list/tree/0.1.4) (2011-07-27)
[Full Changelog](https://github.com/brendon/acts_as_list/compare/0.1.3...0.1.4)

**Merged pull requests:**

- Fix sqlite3 dependency [\#7](https://github.com/brendon/acts_as_list/pull/7) ([joneslee85](https://github.com/joneslee85))

## [0.1.3](https://github.com/brendon/acts_as_list/tree/0.1.3) (2011-06-10)
**Closed issues:**

- Graph like behaviour [\#5](https://github.com/brendon/acts_as_list/issues/5)
- Updated Gem? [\#4](https://github.com/brendon/acts_as_list/issues/4)

**Merged pull requests:**

- Converted into a gem... plus some slight refactors [\#6](https://github.com/brendon/acts_as_list/pull/6) ([chaffeqa](https://github.com/chaffeqa))
- Fixed test issue for test\_injection: expected SQL was reversed. [\#3](https://github.com/brendon/acts_as_list/pull/3) ([afriqs](https://github.com/afriqs))
- Added an option to set the top of the position [\#2](https://github.com/brendon/acts_as_list/pull/2) ([danielcooper](https://github.com/danielcooper))
- minor change to acts\_as\_list's callbacks [\#1](https://github.com/brendon/acts_as_list/pull/1) ([tiegz](https://github.com/tiegz))
