(function($) {
    var ContextMenuClass = function(el, options) {
        var element = el;
        var opts = options;
        var observingContextMenuClick;
        var observingToggleAllClick;
        var lastSelected = null;
        var menu;
        var menuId = 'context-menu';
        var selectorName = 'hascontextmenu';
        var contextMenuSelectionClass = 'context-menu-selection';
        var reverseXClass = 'reverse-x';
        var reverseYClass = 'reverse-y';

        var methods = {
            createMenu: function() {
                if(!menu) {
                    $('#wrapper').append('<div id="' + menuId + '" style="display:none"></div>');
                    menu = $('#' + menuId);
                }
            },
            click: function(e) {
                var target = $(e.target);

                if(target.is('a')) {
                    return;
                }

                switch(e.which) {
                    case 1:
                        if(e.type === 'click') {
                            methods.hideMenu();
                            methods.leftClick(e);
                            break;
                        }
                    case 3:
                        if(e.type === 'contextmenu') {
                            methods.hideMenu();
                            methods.rightClick(e);
                            break;
                        }
                    default:
                        return;
                }
            },
            leftClick: function(e) {
                var target = $(e.target);
                var tr = target.parents('tr');
                if((tr.size() > 0) && tr.hasClass(selectorName))
                {
                    // a row was clicked, check if the click was on checkbox
                    if(target.is('input'))
                    {
                        // a checkbox may be clicked
                        if (target.is(':checked')) {
                            tr.addClass(contextMenuSelectionClass);
                        } else {
                            tr.removeClass(contextMenuSelectionClass);
                        }
                    }
                    else
                    {
                        if (e.ctrlKey || e.metaKey)
                        {
                            methods.toggleSelection(tr);
                        }
                        else if (e.shiftKey)
                        {
                            if (lastSelected !== null)
                            {
                                var toggling = false;
                                var rows = $('.' + selectorName);
                                rows.each(function() {
                                    var self = $(this);
                                    if(toggling || (self.get(0) == tr.get(0))) {
                                        methods.addSelection(self);
                                    }
                                    if(((self.get(0) == tr.get(0)) || (self.get(0) == lastSelected.get(0)))
                                        && (tr.get(0) !== lastSelected.get(0))) {
                                        toggling = !toggling;
                                    }
                                });
                            } else {
                                methods.addSelection(tr);
                            }
                        } else {
                            methods.unselectAll();
                            methods.addSelection(tr);
                        }
                        lastSelected = tr;
                    }
                }
                else
                {
                    // click is outside the rows
                    if (target.is('a') === false) {
                        this.unselectAll();
                    } else {
                        if (target.hasClass('disabled') || target.hasClass('submenu')) {
                            e.preventDefault();
                        }
                    }
                }
            },
            rightClick: function(e) {
                var target = $(e.target);
                var tr = target.parents('tr');

                if((tr.size() === 0) || !(tr.hasClass(selectorName))) {
                    return;
                }
                e.preventDefault();

                if(!methods.isSelected(tr)) {
                    methods.unselectAll();
                    methods.addSelection(tr);
                    lastSelected = tr;
                }
                methods.showMenu(e);
            },
            unselectAll: function() {
                var rows = $('.' + contextMenuSelectionClass);
                rows.each(function() {
                    methods.removeSelection($(this));
                });
            },
            hideMenu: function() {
               menu.hide();
            },
            showMenu: function(e) {
                var target = $(e.target);
                var params = target.parents('form').serialize();

                var mouseX = e.pageX;
                var mouseY = e.pageY;
                var renderX = mouseX;
                var renderY = mouseY;

                $.ajax({
                    url: opts.url,
                    data: params,
                    success: function(response, success) {
                        menu.html(response);

                        var maxWidth = mouseX + (2 * menu.width());
                        var maxHeight = mouseY + menu.height();

                        if(maxWidth > $(window).width()) {
                            renderX -= menu.width();
                            menu.addClass(reverseXClass);
                        } else {
                            menu.removeClass(reverseXClass);
                        }

                        if(maxHeight > $(window).height()) {
                            renderY -= menu.height();
                            menu.addClass(reverseYClass);
                        } else {
                            menu.removeClass(reverseYClass);
                        }

                        if(renderX <= 0) {
                            renderX = 1;
                        }
                        if(renderY <= 0) {
                            renderY = 1;
                        }

                        menu.css('top', renderY).css('left', renderX);
                        menu.show();
                    }
                });
            },
            addSelection: function(element) {
               element.addClass(contextMenuSelectionClass);
               methods.checkSelectionBox(element, true);
               methods.clearDocumentSelection();
            },
            isSelected: function(element) {
                return element.hasClass(contextMenuSelectionClass);
            },
            toggleSelection: function(element) {
                if(methods.isSelected(element)) {
                    methods.removeSelection(element);
                } else {
                    methods.addSelection(element);
                }
            },
            removeSelection: function(element) {
                element.removeClass(contextMenuSelectionClass);
                methods.checkSelectionBox(element, false);
            },
            checkSelectionBox: function(element, checked) {
                var inputs = element.find('input');
                inputs.each(function() {
                    inputs.attr('checked', checked ? 'checked' : false);
                });
            },
            toggleIssuesSelection: function(e) {
                e.preventDefault();
                e.stopPropagation();
                var issues = $(this).parents('form').find('tr.issue');
                var checked = methods.isSelected(issues.eq(0));
                issues.each(function() {
                    var self = $(this);
                    if(checked) {
                        methods.removeSelection(self)
                    } else {
                        methods.addSelection(self);
                    }
                });
            },
            clearDocumentSelection: function() {
                if(document.selection) {
                    document.selection.clear();
                } else {
                    window.getSelection().removeAllRanges();
                }
            }
        };

        methods.createMenu();

        if(!observingContextMenuClick) {
            element.bind('click.contextMenu', methods.click);
            element.bind('contextmenu.contextMenu', methods.click);
            observingContextMenuClick = true;
        }

        if(!observingToggleAllClick) {
            element.find('.issues img[alt="Toggle_check"]').bind('click', methods.toggleIssuesSelection);
            observingToggleAllClick = true;
        }

        methods.unselectAll();
    };

    $.fn.ContextMenu = function(u) {
        return this.each(function() {
            new ContextMenuClass($(this), {url: u});
        });
    };
})(jQuery);

/**
 * Wrapper function to support the old way of creating aa context menu.
 */
function ContextMenu() {
    jQuery(document).ContextMenu(arguments);
}
