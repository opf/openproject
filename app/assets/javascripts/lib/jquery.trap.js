/*!
Copyright (c) 2011, 2012 Julien Wajsberg <felash@gmail.com>
All rights reserved.

Official repository: https://github.com/julienw/jquery-trap-input
License is there: https://github.com/julienw/jquery-trap-input/blob/master/LICENSE
This is version 1.2.0.
*/

(function( $, undefined ){

/*
(this comment is after the first line of code so that uglifyjs removes it)

Redistribution and use in source and binary forms, with or without
modification, are permitted without condition.

Although that's not an obligation, I would appreciate that you provide a
link to the official repository.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
*/

/*jshint boss: true, bitwise: true, curly: true, expr: true, newcap: true, noarg: true, nonew: true, latedef: true, regexdash: true */

    var DATA_ISTRAPPING_KEY = "trap.isTrapping";

    function onkeypress(e) {
        if (e.keyCode === 9) {
            var goReverse = !!(e.shiftKey);
            if (processTab(this, e.target, goReverse)) {
                e.preventDefault();
                e.stopPropagation();
            }
        }
    }

    // will return true if we could process the tab event
    // otherwise, return false
    function processTab(container, elt, goReverse) {
        var $focussable = getFocusableElementsInContainer(container),
            curElt = elt,
            index, nextIndex, prevIndex, lastIndex;

        do {
            index = $focussable.index(curElt);
            nextIndex = index + 1;
            prevIndex = index - 1;
            lastIndex = $focussable.length - 1;

            switch(index) {
                case -1:
                    return false; // that's strange, let the browser do its job
                case 0:
                    prevIndex = lastIndex;
                    break;
                case lastIndex:
                    nextIndex = 0;
                    break;
            }

            if (goReverse) {
                nextIndex = prevIndex;
            }

            curElt = $focussable.get(nextIndex);
            if (!curElt || curElt === elt) { return true; }

            try {
                curElt.focus();
            } catch(e) { // IE sometimes throws when an element is not visible
                return true;
            }

        } while ($focussable.length > 1 && elt === elt.ownerDocument.activeElement);

        return true;
    }

    function filterKeepSpeciallyFocusable() {
        return this.tabIndex > 0;
    }

    function filterKeepNormalElements() {
        return !this.tabIndex; // true if no tabIndex or tabIndex == 0
    }

    function sortFocusable(a, b) {
        return (a.t - b.t) || (a.i - b.i);
    }

    function getFocusableElementsInContainer(container) {
        var $container = $(container);
        var result = [],
            cnt = 0;

        fixIndexSelector.enable && fixIndexSelector.enable();

        // leaving away command and details for now
        $container.find("a[href], link[href], [draggable=true], [contenteditable=true], :input:enabled, [tabindex=0]")
            .filter(":visible")
            .filter(filterKeepNormalElements)
            .each(function(i, val) {
                result.push({
                    v: val, // value
                    t: 0, // tabIndex
                    i: cnt++ // index for stable sort
                });
            });

        $container
            .find("[tabindex]")
            .filter(":visible")
            .filter(filterKeepSpeciallyFocusable)
            .each(function(i, val) {
                result.push({
                    v: val, // value
                    t: val.tabIndex, // tabIndex
                    i: cnt++ // index
                });
            });

        fixIndexSelector.disable && fixIndexSelector.disable();

        result = $.map(result.sort(sortFocusable), // needs stable sort
            function(val) {
                return val.v;
            }
        );


        return $(result);

    }

    function trap() {
        this.keydown(onkeypress);
        this.data(DATA_ISTRAPPING_KEY, true);
        return this;
    }

    function untrap() {
        this.unbind('keydown', onkeypress);
        this.removeData(DATA_ISTRAPPING_KEY);
        return this;
    }

    function isTrapping() {
        return !!this.data(DATA_ISTRAPPING_KEY);
    }

    $.fn.extend({
        trap: trap,
        untrap: untrap,
        isTrapping: isTrapping
    });

    // jQuery 1.6.x tabindex attr hooks management
    // this triggers problems for tabindex attribute
    // selectors in IE7-
    // see https://github.com/julienw/jquery-trap-input/issues/3

   var fixIndexSelector = {};

   if ($.find.find && $.find.attr !== $.attr) {
        // jQuery uses Sizzle (this is jQuery >= 1.3)
        // sizzle uses its own attribute handling (in jq 1.6.x and below)
       (function() {
            var tabindexKey = "tabindex";
            var sizzleAttrHandle = $.expr.attrHandle;

            // this function comes directly from jQuery 1.7.2 (propHooks.tabIndex.get)
            // we have to put it here if we want to support jQuery < 1.6 which
            // doesn't have an attrHooks object to reference.
            function getTabindexAttr(elem) {
                // elem.tabIndex doesn't always return the correct value when it hasn't been explicitly set
                // http://fluidproject.org/blog/2008/01/09/getting-setting-and-removing-tabindex-values-with-javascript/
                var attributeNode = elem.getAttributeNode(tabindexKey);

                return attributeNode && attributeNode.specified ?
                    parseInt( attributeNode.value, 10 ) :
                    undefined;
            }

            function fixSizzleAttrHook() {
                // in jQ <= 1.6.x, we add to Sizzle the attrHook from jQuery's attr method
                sizzleAttrHandle[tabindexKey] = sizzleAttrHandle.tabIndex = getTabindexAttr;
            }

            function unfixSizzleAttrHook() {
                delete sizzleAttrHandle[tabindexKey];
                delete sizzleAttrHandle.tabIndex;
            }


            fixIndexSelector = {
                enable: fixSizzleAttrHook,
                disable: unfixSizzleAttrHook
            };
        })();
    }
})( jQuery );