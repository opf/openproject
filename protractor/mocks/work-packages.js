module.exports = function(app) {
  var fs = require('fs');
  var express = require('express');
  var workPackagesRouter = express.Router();
  workPackagesRouter.get('/', function(req, res) {
    res.send({"work_packages":[]});
  });
  workPackagesRouter.get('/:id', function(req, res) {
    fs.readFile(__dirname + '/work-package.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });

  app.use('/api/v3/work_packages', workPackagesRouter);
};
