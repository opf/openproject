**An autocompletion library to autocomplete mentions, smileys etc. just like on Github or Twitter!** [![Build Status](https://travis-ci.org/ichord/At.js.png)](https://travis-ci.org/ichord/At.js)

#### Notice

At.js now **depends on** [Caret.js](https://github.com/ichord/Caret.js).

This branch has been updated to `v0.4.x`. Please read **CHANGELOG.md** for more details.
English Documentation will keep improving. Maybe **you can do me a favor?**

### Demo

http://ichord.github.com/At.js


### Features Preview

* Supports HTML5  [**contentEditable**](https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Content_Editable) elements (NOT include IE 8)
* Can listen to any character and not just '@'. Can set up multiple listeners for different characters with different behavior and data
* Listener events can be bound to multiple inputors.
* Format returned data using templates
* Keyboard controls in addition to mouse
    - `Tab` or `Enter` keys select the value
    - `Up` and `Down` navigate between values (and `Ctrl-P` and `Ctrl-N` also)
    - `Right` and `left` will re-search the keyword.
* Custom data handlers and template renderers using a group of configurable callbacks
* Supports AMD

### Requirements

* jQuery >= 1.7.0.
* [Caret.js](https://github.com/ichord/Caret.js)
    (You can use `Component` or `Bower` to install it.)

### Documentation
https://github.com/ichord/At.js/wiki

### Integrating with your Application

Simply include the following files in your HTML and you are good to go.

```html
<link href="css/jquery.atwho.css" rel="stylesheet">
<script src="http://code.jquery.com/jquery.js"></script>
<script src="js/jquery.caret.js"></script>
<script src="js/jquery.atwho.js"></script>
```

```javascript
$('#inputor').atwho({
    at: "@",
    data:['Peter', 'Tom', 'Anne']
})
```

#### Bower & Component
For installing using Bower you can use `jquery.atwho` and for Component please use `ichord/At.js`.

#### Rails
You can include At.js in your `Rails` application using the gem [`jquery-atwho-rails`](https://github.com/ichord/jquery-atwho-rails).


### Version History

* branch `stable-v0.3` with tag `v0.3.3`
* branch `stable-v0.2` with tag `v0.2.x`
* branch `stable-v0.1.x` and tag `v0.1.7`

### Core Team Members

* [@ichord](https://twitter.com/_ichord)

#### PS
Let me know if you are using **At.js**. It will motivate me to work harder.
And if you like **At.js**, just email me and add your website [here](https://github.com/ichord/At.js/wiki/Sites)
Hope you like it, Thanks! :)

---

Project is a member of the [OSS Manifesto](http://ossmanifesto.org/).
