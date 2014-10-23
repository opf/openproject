module.exports = function(app) {
  var express = require('express');

  var availableColumnsRouter = express.Router();
  availableColumnsRouter.get('/', function(req, res) {
    res.send({
      "available_columns": []
    });
  });

  var customFieldFiltersRouter = express.Router();
  customFieldFiltersRouter.get('/', function(req, res) {
    res.send({
      "custom_field_filters": []
    });
  });

  var groupedRouter = express.Router();
  groupedRouter.get('/', function(req, res) {
    res.send({
      "user_queries": [],
      "queries": []
    });
  });

  app.use('/api/experimental/queries/available_columns',
    availableColumnsRouter);
  app.use('/api/experimental/queries/custom_field_filters',
    customFieldFiltersRouter);
  app.use('/api/experimental/projects/:id/queries/custom_field_filters',
    customFieldFiltersRouter);
  app.use('/api/experimental/queries/grouped', groupedRouter);
};
