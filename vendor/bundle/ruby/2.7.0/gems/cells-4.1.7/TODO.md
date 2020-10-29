# 4.0

* Add tests for with_assets config


* Get rid of the annoying `ActionController` dependency that needs to be passed into each cell. We only need it for "contextual links", when people wanna link to the same page. Make them pass in a URL generator object as a normal argument instead.
* Generated cells will be view models per default.
* Introduce Composition as in Reform, Representable, etc, when passing in a hash.
    ```ruby
      include Composition
      property :id, on: :comment
    ```