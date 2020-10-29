# 0.1.4

* Newlines are now properly reflected in the compiled code.

# 0.1.3

* Do not trim whitespace between ERB tags.

# 0.1.2

* Postfix conditionals are now parsed properly: code such as `<% puts if true %>` now works, thanks to @aiomaster's work.
* `<%@ code %>` now requires an explicit whitespace after the `@` for backward-compatibility.

# 0.1.1

* Introduce the `<%@ %>` tag. This is a built-in capture mechanism. It will assign all block content to a local variable but *not* output it.
* Make comments be recognized before `end`, which fixes a syntax error with `<%# end %>`.
* Don't recognize ERB tags with a string containing "do" as a block.

# 0.1.0

* Internally, we're parsing the ERB template into a SEXP structure and let [Temple](https://github.com/judofyr/temple) compile it to Ruby. Many thanks to the Temple team! 😘
* Yielding ERB blocks will simply return the content, no output buffering with instance variables will happen.
    This allows to pass ERB blocks around and yield them in other objects without having it output twice as in 0.0.2.
* No instance variables are used anymore, output buffering always happens via locals the way [Slim](https://github.com/slim-template/slim) does it. This might result in a minimal speed decrease but cleans up the code and architecture immensely.
* Removed `Erbse::Template`, it was completely unnecessary code.

# 0.0.2

* First release. No escaping is happening and I'm not sure how capture works, yet. But: it's great!
