_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class AuthController
  constructor: ({@client,@meshbluConfig,@password}) ->

  user: (request, response) =>
    {username,password} = request.query

    if username == 'guest' && password == 'guest'
      return response.send('allow')

    if username == 'meshblu' && password == @password
      return @client.setex username, 30, new Date(), =>
        return response.send('allow')

    if username? && !password?
      return @client.exists username, (error, exists) =>
        return response.send('allow') if exists == 1
        console.log 'denied'
        response.send('deny')

    options = _.extend {}, @meshbluConfig,
      uuid: username
      token: password

    meshblu = new MeshbluHttp options
    meshblu.whoami (error) =>
      console.log 'denied' if error?
      return response.send('deny') if error?
      @client.setex username, 30, new Date(), =>
        response.send('allow')

  vhost: (request, response) =>
    response.send('allow')

  resource: (request, response) =>
    {username, resource, name, permission, vhost} = request.query

    allow = false

    if name.match(/[\*\#]/)
      return response.send('deny')

    if username == 'meshblu'
      allow = true

    if /^amq\.(gen-.*|default|topic)$/.test(name) && permission = 'write'
      allow = true

    if /^meshblu[\.\/]/.test(name) && permission = 'write'
      allow = true

    if vhost == 'mqtt'
      name = name.replace /^mqtt-subscription-/, ''

    if _.startsWith name, username
      allow = true

    console.log {username, resource, name, permission, vhost}
    console.log {allow}
    return response.send('allow') if allow
    response.send('deny')

module.exports = AuthController
