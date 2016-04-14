_             = require 'lodash'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server'

class Command
  constructor: ->
    @serverOptions =
      redisUri:       process.env.REDIS_URI
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      meshbluConfig:  new MeshbluConfig().toJSON()
      namespace:      process.env.NAMESPACE || 'rabbitmq-auth'
      password:       process.env.PASSWORD

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    @panic new Error('Missing required environment variable: MESHBLU_HOSTNAME') if _.isEmpty @serverOptions.meshbluConfig.hostname
    @panic new Error('Missing required environment variable: MESHBLU_PORT') if _.isEmpty @serverOptions.meshbluConfig.port
    @panic new Error('Missing required environment variable: MESHBLU_PROTOCOL') if _.isEmpty @serverOptions.meshbluConfig.protocol
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty @serverOptions.redisUri
    @panic new Error('Missing required environment variable: NAMESPACE') if _.isEmpty @serverOptions.namespace
    @panic new Error('Missing required environment variable: PASSWORD') if _.isEmpty @serverOptions.password

    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()
