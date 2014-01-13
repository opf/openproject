Factory.define('User', Timeline.User)
  .sequence('id')
  .sequence('name', function (i) {return "User No. " + i;})
  .sequence('firstname', function (i) {return "Firstname No." + i;})
  .sequence('lastname', function (i) {return "Lastname No." + i;});