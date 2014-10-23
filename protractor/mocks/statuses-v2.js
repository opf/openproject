module.exports = function(app) {
  var fs = require('fs');
  var express = require('express');
  var statusesRouter = express.Router();
  statusesRouter.get('/', function(req, res) {
    fs.readFile(__dirname + '/statuses.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });
  app.use('/api/v2/statuses', statusesRouter);
};
