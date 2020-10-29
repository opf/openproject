## 4.1.7

* `Collection#join` can now be called without a block.

## 4.1.6

* Use `Declarative::Option` and `Declarative::Builder` instead of `uber`'s. This allows removing the `uber` version restriction.

## 4.1.5

* Fix a bug where nested calls of `cell(name, context: {...})` would ignore the new context elements, resulting in the old context being passed on. By adding `Context::[]` the new elements are now properly merged into a **new context hash**. This means that adding elements to the child context won't leak up into the parent context anymore.

## 4.1.4

* Upgrading to Uber 0.1 which handles builders a bit differently.

## 4.1.3

* Load `Uber::InheritableAttr` in `Testing` to fix a bug in `cells-rspec`.

## 4.1.2

* Testing with Rails 5 now works, by removing code the last piece of Rails-code (I know, it sounds bizarre).

## 4.1.1

* Fix rendering of `Collection` where in some environments (Rails), the overridden `#call` method wouldn't work and strings would be escaped.

## 4.1.0

### API Fix/Changes

* All Rails code removed. Make sure to use [Cells-rails](https://github.com/trailblazer/cells-rails) if you want the old Rails behavior.
* The `builds` feature is now optional, you have to include `Builder` in your cell.
    ```ruby
    class CommentCell < Cell::ViewModel
      include Cell::Builder

      builds do |..|
    ```

* A basic, rendering `#show` method is now provided automatically.
* `ViewModel#render` now accepts a block that can be `yield`ed in the view.
* Passing a block to `ViewModel#call` changed. Use `tap` if you want the "old" behavior (which was never official or documented).
    ```ruby
    Comment::Cell.new(comment).().tap { |cell| }
    ```
    The new behavior is to pass that block to your state method. You can pass it on to `render`, and then `yield` it in the template.

    ```ruby
    def show(&block)
      render &block # yield in show.haml
    end
    ```

    Note that this happens automatically in the default `ViewModel#show` method.
* `Concept#cell` now will resolve a concept cell (`Song::Cell`), and not the old-style suffix cell (`SongCell`). The same applies to `Concept#concept`.

    ```ruby
    concept("song/cell", song).cell("song/cell/composer") #=> resolves to Song::Cell::Composer
    ```
    This decision has been made in regards of the upcoming Cells 5. It simplifies code dramatically, and we consider it unnatural to mix concept and suffix cells in applications.
* In case you were using `@parent_controller`, this doesn't exist anymore (and was never documented, either). Use `context[:controller]`.
* `::self_contained!` is no longer included into `ViewModel`. Please try using `Trailblazer::Cell` instead. If you still need it, here's how.

    ```ruby
    class SongCell < Cell::ViewModel
      extend SelfContained
      self_contained!
    ```
* `Cell::Concept` is deprecated and you should be using the excellent [`Trailblazer::Cell`](https://github.com/trailblazer/trailblazer-cells) class instead, because that's what a concept cell tries to be in an awkward way. The latter is usable without Trailblazer.

    We are hereby dropping support for `Cell::Concept` (it still works).

* Deprecating `:collection_join` and `:method` for collections.

### Awesomeness

* Introduced the concept of a context object that is being passed to all nested cells. This object is supposed to contain dependencies such as `current_user`, in Rails it contains the "parent_controller" under the `context[:controller]` key.

    Simple provide it as an option when rendering the cell.

    ```ruby
    cell(:song, song, context: { current_user: current_user })
    ```

    The `#context` method allows to access this very hash.

    ```ruby
    def role
      context[:current_user].admin? "Admin" : "A nobody"
    end
    ```
* The `cell` helper now allows to pass in a constant, too.

    ```ruby
    cell(Song::Cell, song)
    ```
* New API for `:collection`. If used in views, this happens automatically, but here's how it works now.

    ```ruby
    cell(:comment, collection: Comment.all).() # will invoke show.
    cell(:comment, collection: Comment.all).(:item) # will invoke item.
    cell(:comment, collection: Comment.all).join { |cell, i| cell.show(index: i) }
    ```
    Basically, a `Collection` instance is returned that optionally allows to invoke each cell manually.
* Layout cells can now be injected to wrap the original content.
    ```ruby
    cell(:comment, Comment.find(1), layout: LayoutCell)
    ```

    The LayoutCell will be instantiated and the `show` state invoked. The content cell's content is passed as a block, allowing the layout's view to `yield`.

    This works with `:collection`, too.

## 4.0.5

* Fix `Testing` so you can use Capybara matchers on `cell(:song, collection: [..])`.

## 4.0.4

* `Escaped::property` now properly escapes all passed properties. Thanks @xzo and @jlogsdon!

## 4.0.3

* `Cell::Partial` now does _append_ the global partial path to its `view_paths` instead of using `unshift` and thereby removing possible custom paths.
* Adding `Cell::Translation` which allows using the `#t` helper. Thanks to @johnlane.
* Performance improvement: when inflecting the view name (90% likely to be done) the `caller` is now limited to the data we need, saving memory. Thanks @timoschilling for implementing this.
* In the `concept` helper, we no longer use `classify`, which means you can say `concept("comment/data")` and it will instantiate `Comment::Data` and not `Comment::Datum`. Thanks @firedev!

## 4.0.2

* In Rails, include `ActionView::Helpers::FormHelper` into `ViewModel` so we already have (and pollute our cell with) `UrlHelper` and `FormTagHelper`. Helpers, so much fun.
* Concept cells will now infer their name properly even if the string `Cell` appears twice.

## 4.0.1

* Support forgery protection in `form_tag`.

## 4.0.0

* **Rails Support:** Rails 4.0+ is fully supported, in older versions some form helpers do not work. Let us know how you fixed this.
* **State args:** View models don't use state args. Options are passed into the constructor and saved there. That means that caching callbacks no longer receive arguments as everything is available via the instance itself.
* `ViewModel.new(song: song)` won't automatically create a reader `#song`. You have to configure the cell to use a Struct twin {TODO: document}
* **HTML Escaping:** Escaping only happens for defined `property`s when `Escaped` is included.
* **Template Engines:** There's now _one_ template engine (e.g. ERB or HAML) per cell class. It can be set by including the respective module (e.g. `Cell::Erb`) into the cell class. This happens automatically in Rails.
* **File Naming**. The default filename just uses the engine suffix, e.g. `show.haml`. If you have two different engine formats (e.g. `show.haml` and `show.erb`), use the `format:` option: `render format: :erb`.
    If you need to render a specific mime type, provide the filename: `render view: "show.html"`.
* Builder blocks are no longer executed in controller context but in the context they were defined. This is to remove any dependencies to the controller. If you need e.g. `params`, pass them into the `#cell(..)` call.
* Builders are now defined using `::builds`, not `::build`.

### Removed

* `Cell::Rails` and `Cell::Base` got removed. Every cell is `ViewModel` or `Concept` now.
* All methods from `AbstractController` are gone. This might give you trouble in case you were using `helper_method`. You don't need this anymore - every method included in the cell class is a "helper" in the view (it's one and the same method call).


## 4.0.0.rc2

* Include `#protect_from_forgery?` into Rails cells. It returns false currently.
* Fix `Concept#cell` which now instantiates a cell, not a concept cell.

## 4.0.0.rc1

* Move delegations of `#url_options` etc. to the railtie, which makes it work.

## 4.0.0.beta6

* Removed `ViewModel::template_engine`. This is now done explicitly by including `Cell::Erb`, etc. and happens automatically in a Rails environment.

## 4.0.0.beta5

* Assets bundled in engine cells now work.
* Directory change: Assets like `.css`, `.coffee` and `.js`, no longer have their own `assets/` directory but live inside the views directory of a cell. It turned out that two directories `views/` and `assets/` was too noisy for most users. If you think you have a valid point for re-introducing it, email me, it is not hard to implement.
* When bundling your cell's assets into the asset pipeline, you have to specify the full name of your cell. The names will be constantized.

    ```ruby
    config.cells.with_assets = ["song/cell", "user_cell"] #=> Song::Cell, UserCell
    ```
* `ViewModel` is now completely decoupled from Rails and doesn't inherit from AbstractController anymore.
* API change: The controller dependency is now a second-class citizen being passed into the cell via options.

    ```ruby
    Cell.new(model, {controller: ..})
    ```
* Removing `actionpack` from gemspec.

## 4.0.0.beta4

* Fixed a bug when rendering more than once with ERB, the output buffer was being reused.
*  API change: ViewModel::_prefixes now returns the "fully qualified" pathes including the view paths, prepended to the prefixes. This allows multiple view paths and basically fixes cells in engines.
* The only public way to retrieve prefixes for a cell is `ViewModel::prefixes`. The result is cached.


## 4.0.0.beta3

* Introduce `Cell::Testing` for Rspec and MiniTest.
* Add ViewModel::OutputBuffer to be used in Erbse and soon in Haml.

## 3.11.2

* `ViewModel#call` now accepts a block and yields `self` (the cell instance) to it. This is handy to use with `content_for`.
    ```ruby
      = cell(:song, Song.last).call(:show) do |cell|
        content_for :footer, cell.footer
    ```

## 3.11.1

* Override `ActionView::Helpers::UrlHelper#url_for` in Rails 4.x as it is troublesome. That removes the annoying
    `arguments passed to url_for can't be handled. Please require routes or provide your own implementation`
    exception when using simple_form, form_for, etc with a view model.


## 3.11.0

* Deprecated `Cell::Rails::ViewModel`, please inherit: `class SongCell < Cell::ViewModel`.
* `ViewModel#call` is now the prefered way to invoke the rendering flow. Without any argument, `call` will run `render_state(:show)`. Pass in any method name you want.
* Added `Caching::Notifications`.
* Added `cell(:song, collection: [song1, song2])` to render collections. This only works with ViewModel (and, of course, Concept, too).
* Added `::inherit_views` to only inherit views whereas real class inheritance would inherit all the dark past of the class.
* `::build_for` removed/privatized/changed. Use `Cell::Base::cell_for` instead.
* `Base::_parent_prefixes` is no longer used, if you override that somewhere in your cells it will break. We have our own implementation for computing the controller's prefixes in `Cell::Base::Prefixes` (simpler).
* `#expire_cell_state` doesn't take symbols anymore, only the real cell class name.
* Remove `Cell::Base.setup_view_paths!` and `Cell::Base::DEFAULT_VIEW_PATHS` and the associated Railtie. I don't know why this code survived 3 major versions, if you wanna set you own view paths just use `Cell::Base.view_paths=`.
* Add `Base::self_contained!`.
* Add `Base::inherit_views`.

### Concept
* `#concept` helper is mixed into all views as an alternative to `#cell` and `#render_cell`. Let us know if we should do that conditionally, only.
* Concept cells look for layouts in their self-contained views directory.
* Add generator for Concept cells: `rails g concept Comment`


## 3.10.1
Allow packaging assets for Rails' asset pipeline into cells. This is still experimental but works great. I love it.

## 3.10.0

* API CHANGE: Blocks passed to `::cache` and `::cache ... if: ` no longer receive the cell instance as the first argument. Instead, they're executed in cell instance context. Change your code like this:
```ruby
cache :show do |cell, options|
  cell.version
end
# and
cache :show, if: lambda {|cell, options| .. }
```
should become

```ruby
cache :show do |options|
  version
end
# and
cache :show, if: lambda {|options| .. }
```

Since the blocks are run in cell context, `self` will point to what was `cell` before.


* `::cache` doesn't accept a `Proc` instance anymore, only blocks (was undocumented anyway).
* Use [`uber` gem](https://github.com/apotonick/uber) for inheritable class attributes and dynamic options.

## 3.9.2

* Autoload `Cell::Rails::ViewModel`.
* Implement dynamic cache options by allowing lambdas that are executed at render-time - Thanks to @bibendi for this idea.

## 3.9.1

* Runs with Rails 4.1 now.
* Internal changes on `Layouts` to prepare 4.1 compat.

## 3.9.0

* Cells in engines are now recognized under Rails 4.0.
* Introducing @#cell@ and @#cell_for@ to instantiate cells in ActionController and ActionView.
* Adding @Cell::Rails::ViewModel@ as a new "dialect" of working with cells.
* Add @Cell::Base#process_args@ which is called in the initializer to handle arguments passed into the constructor.
* Setting @controller in your @Cell::TestCase@ no longer get overridden by us.

## 3.8.8

* Maintenance release.

## 3.8.7

* Cells runs with Rails 4.

## 3.8.6

* @cell/base@ can now be required without trouble.
* Generated test files now respect namespaced cells.

## 3.8.5

* Added @Cell::Rails::HelperAPI@ module to provide the entire Rails view "API" (quotes on purpose!) in cells running completely outside of Rails. This makes it possible to use gems like simple_form in any Ruby environment, especially interesting for people using Sinatra, webmachine, etc.
* Moved @Caching.expire_cache_key@ to @Rails@. Use @Caching.expire_cache_key_for(key, cache_store, ..)@ if you want to expire caches outside of Rails.

## 3.8.4

* Added @Cell::Rack@ for request-dependent Cells. This is also the new base class for @Cells::Rails@.
* Removed deprecation warning from @TestCase#cell@ as it's signature is not deprecated.
* Added the @base_cell_class@ config option to generator for specifying an alternative base class.

## 3.8.3

* Added @Engines.existent_directories_for@ to prevent Rails 3.0 from crashing when it detects engines.

## 3.8.2

* Engines should work in Rails 3.0 now, too.

## 3.8.1

* Make it work with Rails 3.2 by removing deprecated stuff.

## 3.8.0

* @Cell::Base@ got rid of the controller dependency. If you want the @ActionController@ instance around in your cell, use @Cell::Rails@ - this should be the default in a standard Rails setup. However, if you plan on using a Cell in a Rack middleware or don't need the controller, use @Cell::Base@.
* New API (note that @controller@ isn't the first argument anymore):
** @Rails.create_cell_for(name, controller)@
** @Rails.render_cell_for(name, state, controller, *args)@
* Moved builder methods to @Cell::Builder@ module.
* @DEFAULT_VIEW_PATHS@ is now in @Cell::Base@.
* Removed the monkey-patch that made state-args work in Rails <= 3.0.3. Upgrade to +3.0.4.

## 3.7.1

* Works with Rails 3.2, too. Hopefully.

## 3.7.0

h3. Changes
  * Cache settings using @Base.cache@ are now inherited.
  * Removed <code>@opts</code>.
  * Removed @#options@ in favor of state-args. If you still want the old behaviour, include the @Deprecations@ module in your cell.
  * The build process is now instantly delegated to Base.build_for on the concrete cell class.

## 3.6.8

h3. Changes
  * Removed <code>@opts</code>.
  * Deprecated @#options@ in favour of state-args.

## 3.6.7

h3. Changes
  * Added @view_assigns@ to TestCase.

## 3.6.6

h3. Changes
  * Added the @:format@ option for @#render@ which should be used with caution. Sorry for that.
  * Removed the useless @layouts/@ view path from Cell::Base.

## 3.6.5

h3. Bugfixes
  * `Cell::TestCase#invoke` now properly accepts state-args.

h3. Changes
  * Added the `:if` option to `Base.cache` which allows adding a conditional proc or instance method to the cache definition. If it doesn't return true, caching for that state is skipped.


## 3.6.4

h3. Bugfixes
  * Fixes @ArgumentError: wrong number of arguments (1 for 0)@ in @#render_cell@ for Ruby 1.8.


## 3.6.3

h3. Bugfixes
  * [Rails 3.0] Helpers are now properly included (only once). Thanks to [paneq] for a fix.
  * `#url_options` in the Metal module is now delegated to `parent_controller` which propagates global URL setting like relative URLs to your cells.

h3. Changes
  * `cells/test_case` is no longer required as it should be loaded automatically.


## 3.6.2

h3. Bugfixes
  * Fixed cells.gemspec to allow Rails 3.x.

## 3.6.1

h3. Changes
  * Added the @:format@ option allowing @#render@ to set different template types, e.g. @render :format => :json@.


## 3.6.0

h3. Changes
  * Cells runs with Rails 3.0 and 3.1.


## 3.5.6

h3. Changes
  * Added a generator for slim. Use it with `-e slim` when generating.


## 3.5.5

h3. Bugfixes
  * The generator now places views of namespaced cells into the correct directory. E.g. `rails g Blog::Post display` puts views to `app/cells/blog/post/display.html.erb`.

h3. Changes
  * Gem dependencies changed, we now require @actionpack@ and @railties@ >= 3.0.0 instead of @rails@.


## 3.5.4

h3. Bugfixes
  * state-args work even if your state method receives optional arguments or default values, like @def show(user, age=18)@.

h3. Changes

  * Cell::Base.view_paths is now setup in an initializer. If you do scary stuff with view_paths this might lead to scary problems.
  * Cells::DEFAULT_VIEW_PATHS is now Cell::Base::DEFAULT_VIEW_PATHS. Note that Cells will set its view_paths to DEFAULT_VIEW_PATHS at initialization time. If you want to alter the view_paths, use Base.append_view_path and friends in a separate initializer.


## 3.5.2

h3. Bugfixes
  * Controller#render_cell now accepts multiple args as options.

h3. Changes
  * Caching versioners now can accept state-args or options from the #render_cell call. This way, you don't have to access #options at all anymore.


## 3.5.1

  * No longer pass an explicit Proc but a versioner block to @Cell.Base.cache@. Example: @cache :show do "v1" end@
  * Caching.cache_key_for now uses @ActiveSupport::Cache.expand_cache_key@. Consequently, a key which used to be like @"cells/director/count/a=1/b=2"@ now is @cells/director/count/a=1&b=2@ and so on. Be warned that this might break your home-made cache expiry.
  * Controller#expire_cell_state now expects the cell class as first arg. Example: @expire_cell_state(DirectorCell, :count)@

h3. Bugfixes
  * Passing options to @render :state@ in views finally works: @render({:state => :list_item}, item, i)@


## 3.5.0

h3. Changes
  * Deprecated @opts, use #options now.
  * Added state-args. State methods can now receive the options as method arguments. This should be the prefered way of parameter exchange with the outer world.
  * #params, #request, and #config is now delegated to @parent_controller.
  * The generator now is invoked as @rails g cell ...@
    * The `--haml` option is no longer available.
    * The `-t` option now is compatible with the rest of rails generators, now it is used as alias for `--test-framework`. Use the `-e` option	as an alias of `--template-engine`
    Thanks to Jorge Calás Lozano <calas@qvitta.net> for patching this in the most reasonable manner i could imagine.
  * Privatized @#find_family_view_for_state@, @#render_view_for@, and all *ize methods in Cell::Rails.
  * New signature: @#render_view_for(state, *args)@

## 3.4.4

h3. Changes
  * Cells.setup now yields Cell::Base, so you can really call append_view_path and friends here.
  * added Cell::Base.build for streamlining the process of deciders around #render_cell, "see here":http://nicksda.apotomo.de/2010/12/pragmatic-rails-thoughts-on-views-inheritance-view-inheritance-and-rails-304
  * added TestCase#in_view to test helpers in a real cell view.


## 3.4.3

h3. Changes
  * #render_cell now accepts a block which yields the cell instance before rendering.

h3. Bugfixes
  * We no longer use TestTaskWithoutDescription in our rake tasks.
