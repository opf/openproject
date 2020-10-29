## Hash

`script`/`style-src` hashes can be used to whitelist inline content that is static. This has the benefit of allowing inline content without opening up the possibility of dynamic javascript like you would with a `nonce`.

You can add hash sources directly to your policy :

```ruby
::SecureHeaders::Configuration.default do |config|
   config.csp = {
     default_src: %w('self')

     # this is a made up value but browsers will show the expected hash in the console.
     script_src: %w(sha256-123456)
   }
 end
 ```

 You can also use the automated inline script detection/collection/computation of hash source values in your app.

 ```bash
 rake secure_headers:generate_hashes
 ```

 This will generate a file (`config/secure_headers_generated_hashes.yml` by default, you can override by setting `ENV["secure_headers_generated_hashes_file"]`) containing a mapping of file names with the array of hash values found on that page. When ActionView renders a given file, we check if there are any known hashes for that given file. If so, they are added as values to the header.

```yaml
---
scripts:
  app/views/asdfs/index.html.erb:
  - "'sha256-yktKiAsZWmc8WpOyhnmhQoDf9G2dAZvuBBC+V0LGQhg='"
styles:
  app/views/asdfs/index.html.erb:
  - "'sha256-SLp6LO3rrKDJwsG9uJUxZapb4Wp2Zhj6Bu3l+d9rnAY='"
  - "'sha256-HSGHqlRoKmHAGTAJ2Rq0piXX4CnEbOl1ArNd6ejp2TE='"
```

##### Helpers

**This will not compute dynamic hashes** by design. The output of both helpers will be a plain `script`/`style` tag without modification and the known hashes for a given file will be added to `script-src`/`style-src` when `hashed_javascript_tag` and `hashed_style_tag` are used. You can use `raise_error_on_unrecognized_hash = true` to be extra paranoid that you have precomputed hash values for all of your inline content. By default, this will raise an error in non-production environments.

```erb
<%= hashed_style_tag do %>
body {
  background-color: black;
}
<% end %>

<%= hashed_style_tag do %>
body {
  font-size: 30px;
  font-color: green;
}
<% end %>

<%= hashed_javascript_tag do %>
console.log(1)
<% end %>
```

```
Content-Security-Policy: ...
 script-src 'sha256-yktKiAsZWmc8WpOyhnmhQoDf9G2dAZvuBBC+V0LGQhg=' ... ;
 style-src 'sha256-SLp6LO3rrKDJwsG9uJUxZapb4Wp2Zhj6Bu3l+d9rnAY=' 'sha256-HSGHqlRoKmHAGTAJ2Rq0piXX4CnEbOl1ArNd6ejp2TE=' ...;
```
