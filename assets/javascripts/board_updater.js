/***************************************
  BOARD UPDATER
  Base object that is extended by
  board-type-specific updaters
***************************************/

RB.BoardUpdater = RB.Object.create({
  
  initialize: function(){
    var self = this;
    
    $('#refresh').bind('click', function(e,u){ self.handleRefreshClick(e,u) });
    $('#disable_autorefresh').bind('click', function(e,u){ self.handleDisableAutorefreshClick(e,u) });

    this.loadPreferences();
    this.pollWait = 1000;
    this.poll()
  },

  adjustPollWait: function(itemsReceived){
    itemsReceived = (itemsReceived==null) ? 0 : itemsReceived;
    
    if(itemsReceived==0 && this.pollWait < 60000 && !$('body').hasClass('no_autorefresh')){
      this.pollWait += 250;
    } else {
      this.pollWait = 1000;
    }
  },

  getData: function(){
    var self = this;
    RB.ajax({
      type      : "GET",
      url       : RB.urlFor[self.urlFor] + '?' + self.params,
      data      : { 
                    after     : $('#last_updated').text(),
                    project_id: RB.constants.project_id
                  },
      beforeSend: function(){ $('body').addClass('loading')  },
      success   : function(d,t,x){ self.processData(d,t,x)  },
      error     : function(){ self.processError() }
    });
  },

  handleDisableAutorefreshClick: function(event, ui){
    $('body').toggleClass('no_autorefresh');
    RB.UserPreferences.set('autorefresh', !$('body').hasClass('no_autorefresh'));
    if(!$('body').hasClass('no_autorefresh')){
      this.pollWait = 1000;
      this.poll();
    }
    this.updateAutorefreshText();
  },

  handleRefreshClick: function(event, ui){
    this.getData();
  },

  loadPreferences: function(){
    var ar = RB.UserPreferences.get('autorefresh')=="true";

    if(ar){
      $('body').removeClass('no_autorefresh');
    } else {
      $('body').addClass('no_autorefresh');
    }
    this.updateAutorefreshText();
  },

  poll: function() {
    if(!$('body').hasClass('no_autorefresh')){
      var self = this;
      setTimeout(function(){ self.getData() }, self.pollWait);
    } else {
      return false;
    }
  },

  processAllItems: function(){
    throw "RB.BoardUpdater.processItems() was not overriden by child object";
  },

  processData: function(data, textStatus, xhr){
    var self = this;

    $('body').removeClass('loading');
    
    var latest_update = $(data).children('#last_updated').text();
    if(latest_update.length > 0) $('#last_updated').text(latest_update);

    self.processAllItems(data);
    self.adjustPollWait($(data).children(":not(.meta)").length);
    self.poll();
  },
  
  processError: function(){
    this.adjustPollWait(0); 
    this.poll();
  },

  updateAutorefreshText: function(){
    if($('body').hasClass('no_autorefresh')){
      $('#disable_autorefresh').text('Enable Auto-refresh');
    } else {
      $('#disable_autorefresh').text('Disable Auto-refresh');
    }
  }
});