AuthController = require './controllers/auth-controller'

class Router
  constructor: ({client,meshbluConfig}) ->
    @authController = new AuthController {client,meshbluConfig}

  route: (app) =>
    app.get '/user', @authController.user
    app.get '/vhost', @authController.vhost
    app.get '/resource', @authController.resource

module.exports = Router
