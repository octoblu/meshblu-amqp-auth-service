http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'authenticate', ->
  beforeEach ->
    @client = new RedisNS 'rabbitmq-auth', redis.createClient()

  beforeEach (done) ->
    @meshblu = shmock 0xd00f

    serverOptions =
      port: undefined,
      disableLogging: true
      namespace: 'rabbitmq-auth'
      meshbluConfig:
        server: 'localhost'
        port: 0xd00f

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  afterEach (done) ->
    @meshblu.close done

  describe 'GET /resource (request.queue, write only)', ->
    beforeEach (done) ->
      options =
        uri: '/resource'
        baseUrl: "http://localhost:#{@serverPort}"
        qs:
          username: 'some-uuid'
          resource: 'queue'
          name: 'request.queue'
          permission: 'write'

      request.get options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200
      expect(@body).to.equal('allow')
