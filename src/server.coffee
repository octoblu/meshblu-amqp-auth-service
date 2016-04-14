cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
MeshbluConfig      = require 'meshblu-config'
debug              = require('debug')('meshblu-rabbitmq-auth-service:server')
Router             = require './router'
redis              = require 'ioredis'
RedisNS            = require '@octoblu/redis-ns'

class Server
  constructor: ({@disableLogging, @port, @meshbluConfig, @redisUri, @namespace, @password})->
    throw new Error 'Server requires namespace' unless @namespace?
    throw new Error 'Server requires password' unless @password?
    throw new Error 'Server requires redisUri' unless @redisUri?
    throw new Error 'Server requires meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server requires port' unless @port?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use bodyParser.urlencoded limit: '1mb', extended : true
    app.use bodyParser.json limit : '1mb'

    app.options '*', cors()

    client = new RedisNS @namespace, redis.createClient(@redisUri)
    client.on 'ready', (error) =>
      return callback error if error?

      router = new Router {@meshbluConfig, client, @password}
      router.route app

      @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
