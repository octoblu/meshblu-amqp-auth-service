http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
enableDestroy = require 'server-destroy'

describe 'authenticate', ->
  beforeEach ->
    @client = new RedisNS 'meshblu-amqp-auth', redis.createClient()

  beforeEach (done) ->
    @meshblu = shmock 0xd00f
    enableDestroy @meshblu

    serverOptions =
      port: undefined,
      disableLogging: true
      namespace: 'meshblu-amqp-auth'
      password: 'judgementday'
      redisUri: 'redis://localhost'
      port: 0xcaff
      meshbluConfig:
        server: 'localhost'
        port: 0xd00f

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  afterEach ->
    @meshblu.destroy()

  describe 'when normal user', ->
    describe 'GET /resource (meshblu.request)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'some-uuid'
            resource: 'queue'
            name: 'meshblu.request'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return deny', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('deny')

    describe 'GET /resource (some-uuid.*)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'some-uuid'
            resource: 'queue'
            name: 'some-uuid.queue'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return allow', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('allow')

    describe 'GET /resource (amq.gen-faoweifj)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'some-uuid'
            resource: 'queue'
            name: 'amq.gen-faoweifj'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return allow', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('allow')

  describe 'when meshblu', ->
    describe 'GET /resource (meshblu.request)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'meshblu'
            resource: 'queue'
            name: 'meshblu.request'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return allow', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('allow')

    describe 'GET /resource (some-uuid.*)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'meshblu'
            resource: 'queue'
            name: 'some-uuid.queue'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return deny', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('deny')

    describe 'GET /resource (amq.gen-faoweifj)', ->
      beforeEach (done) ->
        options =
          uri: '/resource'
          baseUrl: "http://localhost:#{@serverPort}"
          qs:
            username: 'some-uuid'
            resource: 'queue'
            name: 'amq.gen-faoweifj'
            permission: 'write'

        request.get options, (error, @response, @body) =>
          done error

      it 'should return allow', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.equal('allow')
