AuthController = require './controllers/auth-controller'

class Router
  constructor: ({client,meshbluConfig,password}) ->
    @authController = new AuthController {client,meshbluConfig,password}

  route: (app) =>
    app.get '/user', @authController.user
    app.get '/vhost', @authController.vhost
    app.get '/resource', @authController.resource

module.exports = Router
