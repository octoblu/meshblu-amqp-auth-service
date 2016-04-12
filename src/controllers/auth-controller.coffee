_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class AuthController
  constructor: ({@client,@meshbluConfig}) ->

  user: (request, response) =>
    {username,password} = request.query

    if username == 'meshblu' && password == '05539223b927d3091eb1d53dcb31a6ff92cc8edf'
      return @client.setex username, 30, new Date(), =>
        return response.send('allow')

    if username? && !password?
      return @client.exists username, (error, exists) =>
        return response.send('allow') if exists == 1
        response.send('deny')

    options = _.extend {}, @meshbluConfig,
      uuid: username
      token: password

    meshblu = new MeshbluHttp options
    meshblu.whoami (error) =>
      return response.send('deny') if error?
      @client.setex username, 30, new Date(), =>
        response.send('allow')

  vhost: (request, response) =>
    response.send('allow')

  resource: (request, response) =>
    {username, resource, name, permission} = request.query

    if username == 'meshblu'
      return response.send('allow')

    # if name == 'request.queue' && permission == 'configure'
    #   return response.send('allow')

    if _.startsWith name, username
      return response.send('allow')

    if name == 'amq.default'
      return response.send('allow')

    if resource == 'queue' && name == 'request.queue' && permission == 'write'
      return response.send('allow')

    response.send('deny')

module.exports = AuthController
