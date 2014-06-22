routes = (app) ->
  app.get '/', (req, res)->
    res.render 'index',
      name: 'Express user'

module.exports = routes
