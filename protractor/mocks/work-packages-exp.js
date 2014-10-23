module.exports = function(app) {
  var fs = require('fs');
  var express = require('express');
  var workPackagesRouter = express.Router();
  workPackagesRouter.get('/', function(req, res) {
    fs.readFile(__dirname + '/work-packages.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });
  app.use('/api/experimental/work_packages', workPackagesRouter);
};
