This file keeps track of some shortcuts taken while developing % Complete new calculation.

They should eventually be addressed.

* Add feature test to ensure that in Gantt charts, when customizing the display to have % Complete in the chart, the value being displayed does not have the total " . ∑ xx%" in it. It should only display the percentage value.
* Rename "derived" fields as "total" fields in spec files
* Remove the leading attribute name in validation messages in popover for work and remaining work
  * How to: see https://www.bigbinary.com/blog/rails-6-allows-to-override-the-activemodel-errors-full_message-format-at-the-model-level-and-at-the-attribute-level?ref=writesoftwarewell.com
  * Link to discussion with Parimal: https://matrix.to/#/!abggwvHnVGESiAdLKR:openproject.org/$9ommjHQiGj4lTFpBKOCzcUQpp-leaC5-b7jgisTy9VA?via=openproject.org
* Harmonize messages for validation of negative work values for work and remaining work
  * "Work must be >= 0": one we created ourself in https://github.com/opf/openproject/commit/15f52bcdc6cc50c30e14c213133cab4d59715347
  * "Remaining work must be greater than or equal to 0" is the standard rails message (builtin. no translation needed)
* In `app/services/work_packages/update_ancestors_service.rb`, `WorkPackage::UpdateAncestorsService#derive_attributes` is updating both `derived_estimated_hours` and `derived_remaining_hours` even when only one needs to be updated. This is because the tests depend on this behavior. (not sure that's worth modifying)
*
