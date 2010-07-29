// Initialize everything after DOM is loaded
$(function() {  
  RB.Factory.initialize(RB.Taskboard, $('#taskboard'));
  RB.TaskboardUpdater.start();
});