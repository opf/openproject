// Initialize everything after DOM is loaded
$(function() {
  // Initialize each task
  $('#taskboard').each(function(index){
    o = RB.Factory.initialize(RB.Taskboard, this); // 'this' refers to an element with class="taskboard"
  });
});
