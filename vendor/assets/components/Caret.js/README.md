Caret.js
========

Get caret postion or offset from inputor

This is the core function that working in [At.js](http://ichord.github.com/At.js).  
Now, It just become an simple jquery plugin so that everybody can use it.  
And, of course, **At.js** is using this plugin too.

* support iframe context

Live Demo
=========

http://ichord.github.com/Caret.js/


Usage
=====

```javascript

// Get caret position
// not working in `contentEditable` mode
$('#inputor').caret('position'); // => {left: 15, top: 30, height: 20}
$('#inputor').caret('iframe', iframe1).caret('position')

// Get caret offset
$('#inputor').caret('offset'); // => {left: 300, top: 400, height: 20}

var fixPos = 20
// Get position of the 20th char in the inputor.
// not working in `contentEditable` mode
$('#inputor').caret('position', fixPos);

// Get offset of the 20th char.
// not working in `contentEditable` mode
$('#inputor').caret('offset', fixPos);

// more

// Get caret position from first char in inputor.
$('#inputor').caret('pos'); // => 15

// Set caret position in the inputor
// not working in contentEditable mode
$('#inputor').caret('pos', 15);

// set iframe context
// oftenly you don't need to set iframe context because caret.js will find the iframe object automatically
// but some iframe editor will prevent caret.js to finding for security reasons, 
// so you may have to set the iframe manually
$('#inputor').caret({iframe: theIframe});
$('#inputor').caret('offset');
$('#inputor').caret('pos', 15);

```
