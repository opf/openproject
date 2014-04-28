CHANGELOG
=========

Here is a non-exhaustive list of notable changes to jquery-ujs (oldest
to newest):

- [`085d910a5ec07b69`](https://github.com/rails/jquery-ujs/commit/085d910a5ec07b69f31beabce286141aa26f3005) last version before callback names updated
- [`72d875a8d57c6bb4`](https://github.com/rails/jquery-ujs/commit/72d875a8d57c6bb466170980a5142c66ac74e8f0) callback name updates completed
- [`e076121248913143`](https://github.com/rails/jquery-ujs/commit/e0761212489131437402a92fa8f548a78f685ae2) dropped support for jQuery 1.4, 1.4.1, 1.4.2 (separate [v1.4 branch](https://github.com/rails/jquery-ujs/commits/v1.4) created)
- [`498b35e24cdb14f2`](https://github.com/rails/jquery-ujs/commit/498b35e24cdb14f2d94486e8a1f4a1f661091426) last version before `.callRemote()` removed
- [`ec96408a746d3b06`](https://github.com/rails/jquery-ujs/commit/ec96408a746d3b0692da9249f218a3943fbffc28) `ACCEPTS` header data-type default changed to prefer `:js` but not require it
- [`fc639928d1e15c88`](https://github.com/rails/jquery-ujs/commit/fc639928d1e15c885b85de5b517346db7f963f44) default form method changed from `POST` to `GET`
- [`e9311550fdb3afeb`](https://github.com/rails/jquery-ujs/commit/e9311550fdb3afeb2917bcb1fef39767bf715003) added CSRF Protection to remote requests
- [`a284dd706e7d76e8`](https://github.com/rails/jquery-ujs/commit/a284dd706e7d76e85471ef39ab3efdf07feef374) CSRF fixed - changed to only add if token is present
- [`f9b21b3a3c7c4684`](https://github.com/rails/jquery-ujs/commit/f9b21b3a3c7c46840fed8127a90def26911fad3d) `ajax:before` added back
- [`7f2acc1811f62877`](https://github.com/rails/jquery-ujs/commit/7f2acc1811f62877611e16451530728b5e13dbe7) last version before file-upload aborting behavior added
- [`ca575e184e93b3ef`](https://github.com/rails/jquery-ujs/commit/ca575e184e93b3efe1a858cf598f8a37f0a760cc) added `ajax:aborted:required` and `ajax:aborted:file` event hooks
- [`d2abd6f9df4e4a42`](https://github.com/rails/jquery-ujs/commit/d2abd6f9df4e4a426c17c218b7d5e05004c768d0) fixed submit and bubbling behavior for IE
- [`d59144177d867908`](https://github.com/rails/jquery-ujs/commit/d59144177d86790891fdb99b0e3437312e04fda2) created external api via `$.rails` object
- [`cd357e492de14747`](https://github.com/rails/jquery-ujs/commit/cd357e492de147472a8a2524575acce5d923e640) added support for jQuery 1.6 and dropped support for jQuery 1.4.3
- [`50c06dcc02c1b08c`](https://github.com/rails/jquery-ujs/commit/50c06dcc02c1b08cb7a9b4b8eced54ed685c1c93) added `confirm:complete` event hook which is passed result from confirm dialog
- [`8063d1d47ea6a08e`](https://github.com/rails/jquery-ujs/commit/8063d1d47ea6a08e545e9a6ba3e84af584200e41) made $.rails.confirm and $.rails.ajax functions available in $.rails object
- [`a96c4e9b074998c6`](https://github.com/rails/jquery-ujs/commit/a96c4e9b074998c6b6d102e4573b81c8a76f07a7) added support for jQuery 1.6.1
- [`dad6982dc5926866`](https://github.com/rails/jquery-ujs/commit/dad6982dc592686677e6845e681233c40d2ead27) added support for `data-params` attribute on remote links
- [`5433841d01622345`](https://github.com/rails/jquery-ujs/commit/5433841d01622345f734f22f82394ac035c2f783) removed support for jQuery 1.4.4 and 1.5.x, and added support for jQuery 1.6.2
- [`cd619df9f0daad33`](https://github.com/rails/jquery-ujs/commit/cd619df9f0daad3303aacd4f992fff19158b1e5d) added support for html5 `novalidate` attribute, so required fields validation is not enforced
- [`840ab6ac76b2d5ab`](https://github.com/rails/jquery-ujs/commit/840ab6ac76b2d5ab931841bc3d8567e5b57f183e) added support for jQuery 1.6.3
- [`ba5808e73111fb65`](https://github.com/rails/jquery-ujs/commit/ba5808e73111fb65e91610b078577bb014d9b6d8) added `data-remote` support for checkboxes
- [`6e9a06d45eaf2da1`](https://github.com/rails/jquery-ujs/commit/6e9a06d45eaf2da1036d4c2ead25ff57d0127d03) added `data-disable-with` support for links
- [`89396108ce574080`](https://github.com/rails/jquery-ujs/commit/89396108ce574080f9b877cad74573c5d1ae9aa2) added `data-remote` support for all input types
- [`c01215c3d48ebb9f`](https://github.com/rails/jquery-ujs/commit/c01215c3d48ebb9f9f1059f26efa0c0c9092da2b) added support for jQuery 1.6.4
- [`17f4004310b6ece3`](https://github.com/rails/jquery-ujs/commit/17f4004310b6ece3cb240914932b4d6d46032c24) added support for jQuery 1.7
- [`cb54ae287f5c7320`](https://github.com/rails/jquery-ujs/commit/cb54ae287f5c73207aef2891cdf22212aea5fb86) added support for jQuery 1.7.1
- [`dbb1b5f72a62e59f`](https://github.com/rails/jquery-ujs/commit/dbb1b5f72a62e59f34f6b5be4bee291ee7f3318f) added support for jQuery 1.7.2
- [`8100cf3b2462f144`](https://github.com/rails/jquery-ujs/commit/8100cf3b2462f144e6a0bcef7cb78d05be41755d) created `rails:attachBindings` to allow for customization of
  $.rails object settings
- [`e4ca2045b202cd7a`](https://github.com/rails/jquery-ujs/commit/e4ca2045b202cd7ade97d78c20caa2822c5c28da) created `ajax:send` event to provide access to jqXHR object from
  ajax requests
- [`4382f580766fcdd1`](https://github.com/rails/jquery-ujs/commit/4382f580766fcdd14201c204f43ca5aeb0928501) added support for `data-with-credentials`
- [`12da9fc2f175c8e4`](https://github.com/rails/jquery-ujs/commit/12da9fc2f175c8e445413b15cf6b685deb271d6e) added support for jQuery 1.8.0, removed support for jquery 1.6.x
- [`faeb0ad734ff6867`](https://github.com/rails/jquery-ujs/commit/faeb0ad734ff6867149b8522f9a29081734442e6) added support for jQuery 1.8.1
- [`b6dae4ef4a2d031a`](https://github.com/rails/jquery-ujs/commit/b6dae4ef4a2d031a222627c7f6a4284602f99160) added support for jQuery 1.8.2
- [`6927b82cadf3146c`](https://github.com/rails/jquery-ujs/commit/6927b82cadf3146c2b9ae3028e9b197af64011ca) added support for jQuery 1.8.3
- [`cc356656cc3edf15`](https://github.com/rails/jquery-ujs/commit/cc356656cc3edf1596fd685265187d2f75d1bc7c) added support for jQuery 1.9.0
- [`2f8ccdf26eac199a`](https://github.com/rails/jquery-ujs/commit/2f8ccdf26eac199a11aa1a893a8909bb4650d0fb) added support for jQuery 1.9.1
