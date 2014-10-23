module.exports = function(app) {
  var express = require('express');
  var projectsRouter = express.Router();
  projectsRouter.get('/', function(req, res) {
    res.send({"projects":[]});
  });
  app.use('/api/v3/projects', projectsRouter);
};
