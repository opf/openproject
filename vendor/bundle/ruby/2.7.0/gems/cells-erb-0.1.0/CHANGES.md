# 0.1.0

* The `concat` helper is not supported, anymore. Concatenate to a local string instead.

# 0.0.9

* Limit to erbse-0.0.x.

# 0.0.8

* Introduce `cell/erb.rb` for consistency with all other template gems.

# 0.0.7

* Allow Cells 4.x.

# 0.0.6

* Changed `#tag_options`. We now do escape strings as attributes are double-quoted strings already. It makes sense, thanks Rails.

# 0.0.5

* Fix `#concat`.

# 0.0.4

* Fixed output_buffer issues and more.

# 0.0.3

* Added `#capture` helper that doesn't do escaping, in `Cell::Erb`.
