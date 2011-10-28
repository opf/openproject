/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/control/window
 * @require prototype.js, effects.js, draggable.js, resizable.js, livepipe.js
 */

//adds onDraw and constrainToViewport option to draggable
if(typeof(Draggable) != 'undefined'){
    //allows the point to be modified with an onDraw callback
    Draggable.prototype.draw = function(point) {
        var pos = Position.cumulativeOffset(this.element);
        if(this.options.ghosting) {
            var r = Position.realOffset(this.element);
            pos[0] += r[0] - Position.deltaX; pos[1] += r[1] - Position.deltaY;
        }
        
        var d = this.currentDelta();
        pos[0] -= d[0]; pos[1] -= d[1];
        
        if(this.options.scroll && (this.options.scroll != window && this._isScrollChild)) {
            pos[0] -= this.options.scroll.scrollLeft-this.originalScrollLeft;
            pos[1] -= this.options.scroll.scrollTop-this.originalScrollTop;
        }
        
        var p = [0,1].map(function(i){ 
            return (point[i]-pos[i]-this.offset[i]) 
        }.bind(this));
        
        if(this.options.snap) {
            if(typeof this.options.snap == 'function') {
                p = this.options.snap(p[0],p[1],this);
            } else {
                if(this.options.snap instanceof Array) {
                    p = p.map( function(v, i) {return Math.round(v/this.options.snap[i])*this.options.snap[i] }.bind(this))
                } else {
                    p = p.map( function(v) {return Math.round(v/this.options.snap)*this.options.snap }.bind(this))
                  }
            }
        }
        
        if(this.options.onDraw)
            this.options.onDraw.bind(this)(p);
        else{
            var style = this.element.style;
            if(this.options.constrainToViewport){
                var viewport_dimensions = document.viewport.getDimensions();
                var container_dimensions = this.element.getDimensions();
                var margin_top = parseInt(this.element.getStyle('margin-top'));
                var margin_left = parseInt(this.element.getStyle('margin-left'));
                var boundary = [[
                    0 - margin_left,
                    0 - margin_top
                ],[
                    (viewport_dimensions.width - container_dimensions.width) - margin_left,
                    (viewport_dimensions.height - container_dimensions.height) - margin_top
                ]];
                if((!this.options.constraint) || (this.options.constraint=='horizontal')){ 
                    if((p[0] >= boundary[0][0]) && (p[0] <= boundary[1][0]))
                        this.element.style.left = p[0] + "px";
                    else
                        this.element.style.left = ((p[0] < boundary[0][0]) ? boundary[0][0] : boundary[1][0]) + "px";
                } 
                if((!this.options.constraint) || (this.options.constraint=='vertical')){ 
                    if((p[1] >= boundary[0][1] ) && (p[1] <= boundary[1][1]))
                        this.element.style.top = p[1] + "px";
                  else
                        this.element.style.top = ((p[1] <= boundary[0][1]) ? boundary[0][1] : boundary[1][1]) + "px";               
                }
            }else{
                if((!this.options.constraint) || (this.options.constraint=='horizontal'))
                  style.left = p[0] + "px";
                if((!this.options.constraint) || (this.options.constraint=='vertical'))
                  style.top     = p[1] + "px";
            }
            if(style.visibility=="hidden")
                style.visibility = ""; // fix gecko rendering
        }
    };
}

if(typeof(Prototype) == "undefined")
    throw "Control.Window requires Prototype to be loaded.";
if(typeof(IframeShim) == "undefined")
    throw "Control.Window requires IframeShim to be loaded.";
if(typeof(Object.Event) == "undefined")
    throw "Control.Window requires Object.Event to be loaded.";
/*
    known issues:
        - when iframe is clicked is does not gain focus
        - safari can't open multiple iframes properly
        - constrainToViewport: body must have no margin or padding for this to work properly
        - iframe will be mis positioned during fade in
        - document.viewport does not account for scrollbars (this will eventually be fixed in the prototype core)
    notes
        - setting constrainToViewport only works when the page is not scrollable
        - setting draggable: true will negate the effects of position: center
*/
Control.Window = Class.create({
    initialize: function(container,options){
        Control.Window.windows.push(this);
        
        //attribute initialization
        this.container = false;
        this.isOpen = false;
        this.href = false;
        this.sourceContainer = false; //this is optionally the container that will open the window
        this.ajaxRequest = false;
        this.remoteContentLoaded = false; //this is set when the code to load the remote content is run, onRemoteContentLoaded is fired when the connection is closed
        this.numberInSequence = Control.Window.windows.length + 1; //only useful for the effect scoping
        this.indicator = false;
        this.effects = {
            fade: false,
            appear: false
        };
        this.indicatorEffects = {
            fade: false,
            appear: false
        };
        
        //options
        this.options = Object.extend({
            //lifecycle
            beforeOpen: Prototype.emptyFunction,
            afterOpen: Prototype.emptyFunction,
            beforeClose: Prototype.emptyFunction,
            afterClose: Prototype.emptyFunction,
            //dimensions and modes
            height: null,
            width: null,
            className: false,
            position: 'center', //'center', 'center_once', 'relative', [x,y], [function(){return x;},function(){return y;}]
            offsetLeft: 0, //available only for anchors opening the window, or windows set to position: hover
            offsetTop: 0, //""
            iframe: false, //if the window has an href, this will display the href as an iframe instead of requesting the url as an an Ajax.Request
            hover: false, //element object to hover over, or if "true" only available for windows with sourceContainer (an anchor or any element already on the page with an href attribute)
            indicator: false, //element to show or hide when ajax requests, images and iframes are loading
            closeOnClick: false, //does not work with hover,can be: true (click anywhere), 'container' (will refer to this.container), or element (a specific element)
            iframeshim: true, //whether or not to position an iFrameShim underneath the window 
            //effects
            fade: false,
            fadeDuration: 0.75,
            //draggable
            draggable: false,
            onDrag: Prototype.emptyFunction,
            //resizable
            resizable: false,
            minHeight: false,
            minWidth: false,
            maxHeight: false,
            maxWidth: false,
            onResize: Prototype.emptyFunction,
            //draggable and resizable
            constrainToViewport: false,
            //ajax
            method: 'post',
            parameters: {},
            onComplete: Prototype.emptyFunction,
            onSuccess: Prototype.emptyFunction,
            onFailure: Prototype.emptyFunction,
            onException: Prototype.emptyFunction,
            //any element with an href (image,iframe,ajax) will call this after it is done loading
            onRemoteContentLoaded: Prototype.emptyFunction,
            insertRemoteContentAt: false //false will set this to this.container, can be string selector (first returned will be selected), or an Element that must be a child of this.container
        },options || {});
        
        //container setup
        this.indicator = this.options.indicator ? $(this.options.indicator) : false;
        if(container){
            if(typeof(container) == "string" && container.match(Control.Window.uriRegex))
                this.href = container;
            else{
                this.container = $(container);
                //need to create the container now for tooltips (or hover: element with no container already on the page)
                //second call made below will not create the container since the check is done inside createDefaultContainer()
                this.createDefaultContainer(container);
                //if an element with an href was passed in we use it to activate the window
                if(this.container && ((this.container.readAttribute('href') && this.container.readAttribute('href') != '') || (this.options.hover && this.options.hover !== true))){                        
                    if(this.options.hover && this.options.hover !== true)
                        this.sourceContainer = $(this.options.hover);
                    else{
                        this.sourceContainer = this.container;
                        this.href = this.container.readAttribute('href');
                        var rel = this.href.match(/^#(.+)$/);
                        if(rel && rel[1]){
                            this.container = $(rel[1]);
                            this.href = false;
                        }else
                            this.container = false;
                    }
                    //hover or click handling
                    this.sourceContainerOpenHandler = function(event){
                        if (Event.isLeftClick(event)) {
                          // catches modifier keys
                          if (!(event.shiftKey || event.metaKey || event.ctrlKey || event.altKey)) {
                            this.open(event);
                            event.stop();
                            return false;
                          }
                        }
                        else if (Event.isMiddleClick(event)) {
                          // do nothing - let browser handle the click
                        }
                        else {
                          // must be triggered by hover or such
                          this.open(event);
                          event.stop();
                          return false;
                        }
                    }.bindAsEventListener(this);
                    this.sourceContainerCloseHandler = function(event){
                        this.close(event);
                    }.bindAsEventListener(this);
                    this.sourceContainerMouseMoveHandler = function(event){
                        this.position(event);
                    }.bindAsEventListener(this);
                    if(this.options.hover){
                        this.sourceContainer.observe('mouseenter',this.sourceContainerOpenHandler);
                        this.sourceContainer.observe('mouseleave',this.sourceContainerCloseHandler);
                        if(this.options.position == 'mouse')
                            this.sourceContainer.observe('mousemove',this.sourceContainerMouseMoveHandler);
                    }else
                        this.sourceContainer.observe('click',this.sourceContainerOpenHandler);
                }
            }
        }
        this.createDefaultContainer(container);
        if(this.options.insertRemoteContentAt === false)
            this.options.insertRemoteContentAt = this.container;
        var styles = {
            margin: 0,
            position: 'absolute',
            zIndex: Control.Window.initialZIndexForWindow()
        };
        if(this.options.width)
            styles.width = $value(this.options.width) + 'px';
        if(this.options.height)
            styles.height = $value(this.options.height) + 'px';
        this.container.setStyle(styles);
        if(this.options.className)
            this.container.addClassName(this.options.className);
        this.positionHandler = this.position.bindAsEventListener(this);
        this.outOfBoundsPositionHandler = this.ensureInBounds.bindAsEventListener(this);
        this.bringToFrontHandler = this.bringToFront.bindAsEventListener(this);
        this.container.observe('mousedown',this.bringToFrontHandler);
        this.container.hide();
        this.closeHandler = this.close.bindAsEventListener(this);
        //iframeshim setup
        if(this.options.iframeshim){
            this.iFrameShim = new IframeShim();
            this.iFrameShim.hide();
        }
        //resizable support
        this.applyResizable();
        //draggable support
        this.applyDraggable();
        
        //makes sure the window can't go out of bounds
        Event.observe(window,'resize',this.outOfBoundsPositionHandler);
        
        this.notify('afterInitialize');
    },
    open: function(event){
        if(this.isOpen){
            this.bringToFront();
            return false;
        }
        if(this.notify('beforeOpen') === false)
            return false;
        //closeOnClick
        if(this.options.closeOnClick){
            if(this.options.closeOnClick === true)
                this.closeOnClickContainer = $(document.body);
            else if(this.options.closeOnClick == 'container')
                this.closeOnClickContainer = this.container;
            else if (this.options.closeOnClick == 'overlay'){
                Control.Overlay.load();
                this.closeOnClickContainer = Control.Overlay.container;
            }else
                this.closeOnClickContainer = $(this.options.closeOnClick);
            this.closeOnClickContainer.observe('click',this.closeHandler);
        }
        if(this.href && !this.options.iframe && !this.remoteContentLoaded){
            //link to image
            this.remoteContentLoaded = true;
            if(this.href.match(/\.(jpe?g|gif|png|tiff?)$/i)){
                var img = new Element('img');
                img.observe('load',function(img){
                    this.getRemoteContentInsertionTarget().insert(img);
                    this.position();
                    if(this.notify('onRemoteContentLoaded') !== false){
                        if(this.options.indicator)
                            this.hideIndicator();
                        this.finishOpen();
                    }
                }.bind(this,img));
                img.writeAttribute('src',this.href);
            }else{
                //if this is an ajax window it will only open if the request is successful
                if(!this.ajaxRequest){
                    if(this.options.indicator)
                        this.showIndicator();
                    this.ajaxRequest = new Ajax.Request(this.href,{
                        method: this.options.method,
                        parameters: this.options.parameters,
                        onComplete: function(request){
                            this.notify('onComplete',request);
                            this.ajaxRequest = false;
                        }.bind(this),
                        onSuccess: function(request){
                            this.getRemoteContentInsertionTarget().insert(request.responseText);
                            this.notify('onSuccess',request);
                            if(this.notify('onRemoteContentLoaded') !== false){
                                if(this.options.indicator)
                                    this.hideIndicator();
                                this.finishOpen();
                            }
                        }.bind(this),
                        onFailure: function(request){
                            this.notify('onFailure',request);
                            if(this.options.indicator)
                                this.hideIndicator();
                        }.bind(this),
                        onException: function(request,e){
                            this.notify('onException',request,e);
                            if(this.options.indicator)
                                this.hideIndicator();
                        }.bind(this)
                    });
                }
            }
            return true;
        }else if(this.options.iframe && !this.remoteContentLoaded){
            //iframe
            this.remoteContentLoaded = true;
            if(this.options.indicator)
                this.showIndicator();
            this.getRemoteContentInsertionTarget().insert(Control.Window.iframeTemplate.evaluate({
                href: this.href
            }));
            var iframe = this.container.down('iframe');
            iframe.onload = function(){
                this.notify('onRemoteContentLoaded');
                if(this.options.indicator)
                    this.hideIndicator();
                iframe.onload = null;
            }.bind(this);
        }
        this.finishOpen(event);
        return true
    },
    close: function(event){ //event may or may not be present
        if(!this.isOpen || this.notify('beforeClose',event) === false)
            return false;
        if(this.options.closeOnClick)
            this.closeOnClickContainer.stopObserving('click',this.closeHandler);
        if(this.options.fade){
            this.effects.fade = new Effect.Fade(this.container,{
                queue: {
                    position: 'front',
                    scope: 'Control.Window' + this.numberInSequence
                },
                from: 1,
                to: 0,
                duration: this.options.fadeDuration / 2,
                afterFinish: function(){
                    if(this.iFrameShim)
                        this.iFrameShim.hide();
                    this.isOpen = false;
                    this.notify('afterClose');
                }.bind(this)
            });
        }else{
            this.container.hide();
            if(this.iFrameShim)
                this.iFrameShim.hide();
        }
        if(this.ajaxRequest)
            this.ajaxRequest.transport.abort();
        if(!(this.options.draggable || this.options.resizable) && this.options.position == 'center')
            Event.stopObserving(window,'resize',this.positionHandler);
        if(!this.options.draggable && this.options.position == 'center')
            Event.stopObserving(window,'scroll',this.positionHandler);
        if(this.options.indicator)
            this.hideIndicator();
        if(!this.options.fade){
            this.isOpen = false;
            this.notify('afterClose');
        }
        return true;
    },
    position: function(event){
        //this is up top for performance reasons
        if(this.options.position == 'mouse'){
            var xy = [Event.pointerX(event),Event.pointerY(event)];
            this.container.setStyle({
                top: xy[1] + $value(this.options.offsetTop) + 'px',
                left: xy[0] + $value(this.options.offsetLeft) + 'px'
            });
            return;
        }
        var container_dimensions = this.container.getDimensions();
        var viewport_dimensions = document.viewport.getDimensions();
        Position.prepare();
        var offset_left = (Position.deltaX + Math.floor((viewport_dimensions.width - container_dimensions.width) / 2));
        var offset_top = (Position.deltaY + ((viewport_dimensions.height > container_dimensions.height) ? Math.floor((viewport_dimensions.height - container_dimensions.height) / 2) : 0));
        if(this.options.position == 'center' || this.options.position == 'center_once'){
            this.container.setStyle({
                top: (container_dimensions.height <= viewport_dimensions.height) ? ((offset_top != null && offset_top > 0) ? offset_top : 0) + 'px' : 0,
                left: (container_dimensions.width <= viewport_dimensions.width) ? ((offset_left != null && offset_left > 0) ? offset_left : 0) + 'px' : 0
            });
        }else if(this.options.position == 'relative'){
            var xy = this.sourceContainer.cumulativeOffset();
            var top = xy[1] + $value(this.options.offsetTop);
            var left = xy[0] + $value(this.options.offsetLeft);
            this.container.setStyle({
                top: (container_dimensions.height <= viewport_dimensions.height) ? (this.options.constrainToViewport ? Math.max(0,Math.min(viewport_dimensions.height - (container_dimensions.height),top)) : top) + 'px' : 0,
                left: (container_dimensions.width <= viewport_dimensions.width) ? (this.options.constrainToViewport ? Math.max(0,Math.min(viewport_dimensions.width - (container_dimensions.width),left)) : left) + 'px' : 0
            });
        }else if(this.options.position.length){
            var top = $value(this.options.position[1]) + $value(this.options.offsetTop);
            var left = $value(this.options.position[0]) + $value(this.options.offsetLeft);
            this.container.setStyle({
                top: (container_dimensions.height <= viewport_dimensions.height) ? (this.options.constrainToViewport ? Math.max(0,Math.min(viewport_dimensions.height - (container_dimensions.height),top)) : top) + 'px' : 0,
                left: (container_dimensions.width <= viewport_dimensions.width) ? (this.options.constrainToViewport ? Math.max(0,Math.min(viewport_dimensions.width - (container_dimensions.width),left)) : left) + 'px' : 0
            });
        }
        if(this.iFrameShim)
            this.updateIFrameShimZIndex();
    },
    ensureInBounds: function(){
        if(!this.isOpen)
            return;
        var viewport_dimensions = document.viewport.getDimensions();
        var container_offset = this.container.cumulativeOffset();
        var container_dimensions = this.container.getDimensions();
        if(container_offset.left + container_dimensions.width > viewport_dimensions.width){
            this.container.setStyle({
                left: (Math.max(0,viewport_dimensions.width - container_dimensions.width)) + 'px'
            });
        }
        if(container_offset.top + container_dimensions.height > viewport_dimensions.height){
            this.container.setStyle({
                top: (Math.max(0,viewport_dimensions.height - container_dimensions.height)) + 'px'
            });
        }
    },
    bringToFront: function(){
        Control.Window.bringToFront(this);
        this.notify('bringToFront');
    },
    destroy: function(){
        this.container.stopObserving('mousedown',this.bringToFrontHandler);
        if(this.draggable){
            Draggables.removeObserver(this.container);
            this.draggable.handle.stopObserving('mousedown',this.bringToFrontHandler);
            this.draggable.destroy();
        }
        if(this.resizable){
            Resizables.removeObserver(this.container);
            this.resizable.handle.stopObserving('mousedown',this.bringToFrontHandler);
            this.resizable.destroy();
        }
        if(this.container && !this.sourceContainer)
            this.container.remove();
        if(this.sourceContainer){
            if(this.options.hover){
                this.sourceContainer.stopObserving('mouseenter',this.sourceContainerOpenHandler);
                this.sourceContainer.stopObserving('mouseleave',this.sourceContainerCloseHandler);
                if(this.options.position == 'mouse')
                    this.sourceContainer.stopObserving('mousemove',this.sourceContainerMouseMoveHandler);
            }else
                this.sourceContainer.stopObserving('click',this.sourceContainerOpenHandler);
        }
        if(this.iFrameShim)
            this.iFrameShim.destroy();
        Event.stopObserving(window,'resize',this.outOfBoundsPositionHandler);
        Control.Window.windows = Control.Window.windows.without(this);
        this.notify('afterDestroy');
    },
    //private
    applyResizable: function(){
        if(this.options.resizable){
            if(typeof(Resizable) == "undefined")
                throw "Control.Window requires resizable.js to be loaded.";
            var resizable_handle = null;
            if(this.options.resizable === true){
                resizable_handle = new Element('div',{
                    className: 'resizable_handle'
                });
                this.container.insert(resizable_handle);
            }else
                resizable_handle = $(this.options.resziable);
            this.resizable = new Resizable(this.container,{
                handle: resizable_handle,
                minHeight: this.options.minHeight,
                minWidth: this.options.minWidth,
                maxHeight: this.options.constrainToViewport ? function(element){
                    //viewport height - top - total border height
                    return (document.viewport.getDimensions().height - parseInt(element.style.top || 0)) - (element.getHeight() - parseInt(element.style.height || 0));
                } : this.options.maxHeight,
                maxWidth: this.options.constrainToViewport ? function(element){
                    //viewport width - left - total border width
                    return (document.viewport.getDimensions().width - parseInt(element.style.left || 0)) - (element.getWidth() - parseInt(element.style.width || 0));
                } : this.options.maxWidth
            });
            this.resizable.handle.observe('mousedown',this.bringToFrontHandler);
            Resizables.addObserver(new Control.Window.LayoutUpdateObserver(this,function(){
                if(this.iFrameShim)
                    this.updateIFrameShimZIndex();
                this.notify('onResize');
            }.bind(this)));
        }
    },
    applyDraggable: function(){
        if(this.options.draggable){
            if(typeof(Draggables) == "undefined")
                throw "Control.Window requires dragdrop.js to be loaded.";
            var draggable_handle = null;
            if(this.options.draggable === true){
                draggable_handle = new Element('div',{
                    className: 'draggable_handle'
                });
                this.container.insert(draggable_handle);
            }else
                draggable_handle = $(this.options.draggable);
            this.draggable = new Draggable(this.container,{
                handle: draggable_handle,
                constrainToViewport: this.options.constrainToViewport,
                zindex: this.container.getStyle('z-index'),
                starteffect: function(){
                    if(Prototype.Browser.IE){
                        this.old_onselectstart = document.onselectstart;
                        document.onselectstart = function(){
                            return false;
                        };
                    }
                }.bind(this),
                endeffect: function(){
                    document.onselectstart = this.old_onselectstart;
                }.bind(this)
            });
            this.draggable.handle.observe('mousedown',this.bringToFrontHandler);
            Draggables.addObserver(new Control.Window.LayoutUpdateObserver(this,function(){
                if(this.iFrameShim)
                    this.updateIFrameShimZIndex();
                this.notify('onDrag');
            }.bind(this)));
        }
    },
    createDefaultContainer: function(container){
        if(!this.container){
            //no container passed or found, create it
            this.container = new Element('div',{
                id: 'control_window_' + this.numberInSequence
            });
            $(document.body).insert(this.container);
            if(typeof(container) == "string" && $(container) == null && !container.match(/^#(.+)$/) && !container.match(Control.Window.uriRegex))
                this.container.update(container);
        }
    },
    finishOpen: function(event){
        this.bringToFront();
        if(this.options.fade){
            if(typeof(Effect) == "undefined")
                throw "Control.Window requires effects.js to be loaded."
            if(this.effects.fade)
                this.effects.fade.cancel();
            this.effects.appear = new Effect.Appear(this.container,{
                queue: {
                    position: 'end',
                    scope: 'Control.Window.' + this.numberInSequence
                },
                from: 0,
                to: 1,
                duration: this.options.fadeDuration / 2,
                afterFinish: function(){
                    if(this.iFrameShim)
                        this.updateIFrameShimZIndex();
                    this.isOpen = true;
                    this.notify('afterOpen');
                }.bind(this)
            });
        }else
            this.container.show();
        this.position(event);
        if(!(this.options.draggable || this.options.resizable) && this.options.position == 'center')
            Event.observe(window,'resize',this.positionHandler,false);
        if(!this.options.draggable && this.options.position == 'center')
            Event.observe(window,'scroll',this.positionHandler,false);
        if(!this.options.fade){
            this.isOpen = true;
            this.notify('afterOpen');
        }
        return true;
    },
    showIndicator: function(){
        this.showIndicatorTimeout = window.setTimeout(function(){
            if(this.options.fade){
                this.indicatorEffects.appear = new Effect.Appear(this.indicator,{
                    queue: {
                        position: 'front',
                        scope: 'Control.Window.indicator.' + this.numberInSequence
                    },
                    from: 0,
                    to: 1,
                    duration: this.options.fadeDuration / 2
                });
            }else
                this.indicator.show();
        }.bind(this),Control.Window.indicatorTimeout);
    },
    hideIndicator: function(){
        if(this.showIndicatorTimeout)
            window.clearTimeout(this.showIndicatorTimeout);
        this.indicator.hide();
    },
    getRemoteContentInsertionTarget: function(){
        return typeof(this.options.insertRemoteContentAt) == "string" ? this.container.down(this.options.insertRemoteContentAt) : $(this.options.insertRemoteContentAt);
    },
    updateIFrameShimZIndex: function(){
        if(this.iFrameShim)
            this.iFrameShim.positionUnder(this.container);
    }
});
//class methods
Object.extend(Control.Window,{
    windows: [],
    baseZIndex: 9999,
    indicatorTimeout: 250,
    iframeTemplate: new Template('<iframe src="#{href}" width="100%" height="100%" frameborder="0"></iframe>'),
    uriRegex: /^(\/|\#|https?\:\/\/|[\w]+\/)/,
    bringToFront: function(w){
        Control.Window.windows = Control.Window.windows.without(w);
        Control.Window.windows.push(w);
        Control.Window.windows.each(function(w,i){
            var z_index = Control.Window.baseZIndex + i;
            w.container.setStyle({
                zIndex: z_index
            });
            if(w.isOpen){
                if(w.iFrameShim)
                w.updateIFrameShimZIndex();
            }
            if(w.options.draggable)
                w.draggable.options.zindex = z_index;
        });
    },
    open: function(container,options){
        var w = new Control.Window(container,options);
        w.open();
        return w;
    },
    //protected
    initialZIndexForWindow: function(w){
        return Control.Window.baseZIndex + (Control.Window.windows.length - 1);
    }
});
Object.Event.extend(Control.Window);

//this is the observer for both Resizables and Draggables
Control.Window.LayoutUpdateObserver = Class.create({
    initialize: function(w,observer){
        this.w = w;
        this.element = $(w.container);
        this.observer = observer;
    },
    onStart: Prototype.emptyFunction,
    onEnd: function(event_name,instance){
        if(instance.element == this.element && this.iFrameShim)
            this.w.updateIFrameShimZIndex();
    },
    onResize: function(event_name,instance){
        if(instance.element == this.element)
            this.observer(this.element);
    },
    onDrag: function(event_name,instance){
        if(instance.element == this.element)
            this.observer(this.element);
    }
});

//overlay for Control.Modal
Control.Overlay = {
    id: 'control_overlay',
    loaded: false,
    container: false,
    lastOpacity: 0,
    styles: {
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        zIndex: 9998
    },
    ieStyles: {
        position: 'absolute',
        top: 0,
        left: 0,
        zIndex: 9998
    },
    effects: {
        fade: false,
        appear: false
    },
    load: function(){
        if(Control.Overlay.loaded)
            return false;
        Control.Overlay.loaded = true;
        Control.Overlay.container = new Element('div',{
            id: Control.Overlay.id
        });
        $(document.body).insert(Control.Overlay.container);
        if(Prototype.Browser.IE){
            Control.Overlay.container.setStyle(Control.Overlay.ieStyles);
            Event.observe(window,'scroll',Control.Overlay.positionOverlay);
            Event.observe(window,'resize',Control.Overlay.positionOverlay);
            Control.Overlay.observe('beforeShow',Control.Overlay.positionOverlay);
        }else
            Control.Overlay.container.setStyle(Control.Overlay.styles);
        Control.Overlay.iFrameShim = new IframeShim();
        Control.Overlay.iFrameShim.hide();
        Event.observe(window,'resize',Control.Overlay.positionIFrameShim);
        Control.Overlay.container.hide();
        return true;
    },
    unload: function(){
        if(!Control.Overlay.loaded)
            return false;
        Event.stopObserving(window,'resize',Control.Overlay.positionOverlay);
        Control.Overlay.stopObserving('beforeShow',Control.Overlay.positionOverlay);
        Event.stopObserving(window,'resize',Control.Overlay.positionIFrameShim);
        Control.Overlay.iFrameShim.destroy();
        Control.Overlay.container.remove();
        Control.Overlay.loaded = false;
        return true;
    },
    show: function(opacity,fade){
        if(Control.Overlay.notify('beforeShow') === false)
            return false;
        Control.Overlay.lastOpacity = opacity;
        Control.Overlay.positionIFrameShim();
        Control.Overlay.iFrameShim.show();
        if(fade){
            if(typeof(Effect) == "undefined")
                throw "Control.Window requires effects.js to be loaded."
            if(Control.Overlay.effects.fade)
                Control.Overlay.effects.fade.cancel();
            Control.Overlay.effects.appear = new Effect.Appear(Control.Overlay.container,{
                queue: {
                    position: 'end',
                    scope: 'Control.Overlay'
                },
                afterFinish: function(){
                    Control.Overlay.notify('afterShow');
                },
                from: 0,
                to: Control.Overlay.lastOpacity,
                duration: (fade === true ? 0.75 : fade) / 2
            });
        }else{
            Control.Overlay.container.setStyle({
                opacity: opacity || 1
            });
            Control.Overlay.container.show();
            Control.Overlay.notify('afterShow');
        }
        return true;
    },
    hide: function(fade){
        if(Control.Overlay.notify('beforeHide') === false)
            return false;
        if(Control.Overlay.effects.appear)
            Control.Overlay.effects.appear.cancel();
        Control.Overlay.iFrameShim.hide();
        if(fade){
            Control.Overlay.effects.fade = new Effect.Fade(Control.Overlay.container,{
                queue: {
                    position: 'front',
                    scope: 'Control.Overlay'
                },
                afterFinish: function(){
                    Control.Overlay.notify('afterHide');
                },
                from: Control.Overlay.lastOpacity,
                to: 0,
                duration: (fade === true ? 0.75 : fade) / 2
            });
        }else{
            Control.Overlay.container.hide();
            Control.Overlay.notify('afterHide');
        }
        return true;
    },
    positionIFrameShim: function(){
        if(Control.Overlay.container.visible())
            Control.Overlay.iFrameShim.positionUnder(Control.Overlay.container);
    },
    //IE only
    positionOverlay: function(){
        Control.Overlay.container.setStyle({
            width: document.body.clientWidth + 'px',
            height: document.body.clientHeight + 'px'
        });
    }
};
Object.Event.extend(Control.Overlay);

Control.ToolTip = Class.create(Control.Window,{
    initialize: function($super,container,tooltip,options){
        $super(tooltip,Object.extend(Object.extend(Object.clone(Control.ToolTip.defaultOptions),options || {}),{
            position: 'mouse',
            hover: container
        }));
    }
});
Object.extend(Control.ToolTip,{
    defaultOptions: {
        offsetLeft: 10
    }
});

Control.Modal = Class.create(Control.Window,{
    initialize: function($super,container,options){
        Control.Modal.InstanceMethods.beforeInitialize.bind(this)();
        $super(container,Object.extend(Object.clone(Control.Modal.defaultOptions),options || {}));
    },
    closeWithoutOverlay: function(){
        this.keepOverlay = true;
        this.close();
    }
});
Object.extend(Control.Modal,{
    defaultOptions: {
        overlayOpacity: 0.5,
        closeOnClick: 'overlay'
    },
    current: false,
    open: function(container,options){
        var modal = new Control.Modal(container,options);
        modal.open();
        return modal;
    },
    close: function(){
        if(Control.Modal.current)
            Control.Modal.current.close();
    },
    InstanceMethods: {
        beforeInitialize: function(){
            Control.Overlay.load();
            this.observe('beforeOpen',Control.Modal.Observers.beforeOpen.bind(this));
            this.observe('afterOpen',Control.Modal.Observers.afterOpen.bind(this));
            this.observe('afterClose',Control.Modal.Observers.afterClose.bind(this));
        }
    },
    Observers: {
        beforeOpen: function(){
            Control.Window.windows.without(this).each(function(w){
                if(w.closeWithoutOverlay && w.isOpen){
                    w.closeWithoutOverlay();
                }else{
                    w.close();
                }
            });
            if(!Control.Overlay.overlayFinishedOpening){
                Control.Overlay.observeOnce('afterShow',function(){
                    Control.Overlay.overlayFinishedOpening = true;
                    this.open();
                }.bind(this));
                Control.Overlay.show(this.options.overlayOpacity,this.options.fade ? this.options.fadeDuration : false);
                throw $break;
            }
        },
        afterOpen: function(){
            Control.Overlay.show(this.options.overlayOpacity);
            Control.Overlay.overlayFinishedOpening = true;
            Control.Modal.current = this;
        },
        afterClose: function(){
            if(!this.keepOverlay){
                Control.Overlay.hide(this.options.fade ? this.options.fadeDuration : false);
                Control.Overlay.overlayFinishedOpening = false;
            }
            this.keepOverlay = false;
            Control.Modal.current = false;
        }
    }
});

Control.LightBox = Class.create(Control.Window,{
    initialize: function($super,container,options){
        this.allImagesLoaded = false;
        if(options.modal){
            var options = Object.extend(Object.clone(Control.LightBox.defaultOptions),options || {});
            options = Object.extend(Object.clone(Control.Modal.defaultOptions),options);
            options = Control.Modal.InstanceMethods.beforeInitialize.bind(this)(options);
            $super(container,options);
        }else
            $super(container,Object.extend(Object.clone(Control.LightBox.defaultOptions),options || {}));
        this.hasRemoteContent = this.href && !this.options.iframe;
        if(this.hasRemoteContent)
            this.observe('onRemoteContentLoaded',Control.LightBox.Observers.onRemoteContentLoaded.bind(this));
        else
            this.applyImageObservers();
        this.observe('beforeOpen',Control.LightBox.Observers.beforeOpen.bind(this));
    },
    applyImageObservers:function(){
        var images = this.getImages();
        this.numberImagesToLoad = images.length;
        this.numberofImagesLoaded = 0;
        images.each(function(image){
            image.observe('load',function(image){
                ++this.numberofImagesLoaded;
                if(this.numberImagesToLoad == this.numberofImagesLoaded){
                    this.allImagesLoaded = true;
                    this.onAllImagesLoaded();
                }
            }.bind(this,image));
            image.hide();
        }.bind(this));
    },
    onAllImagesLoaded: function(){
        this.getImages().each(function(image){
            this.showImage(image);
        }.bind(this));
        if(this.hasRemoteContent){
            if(this.options.indicator)
                this.hideIndicator();
            this.finishOpen();
        }else
            this.open();
    },
    getImages: function(){
        return this.container.select(Control.LightBox.imageSelector);
    },
    showImage: function(image){
        image.show();
    }
});
Object.extend(Control.LightBox,{
    imageSelector: 'img',
    defaultOptions: {},
    Observers: {
        beforeOpen: function(){
            if(!this.hasRemoteContent && !this.allImagesLoaded)
                throw $break;
        },
        onRemoteContentLoaded: function(){
            this.applyImageObservers();
            if(!this.allImagesLoaded)
                throw $break;
        }
    }
});
