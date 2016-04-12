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

  describe 'GET /user', ->
    beforeEach (done) ->
      userAuth = new Buffer('some-uuid:some-token').toString 'base64'

      @authDevice = @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{userAuth}"
        .reply 200, uuid: 'some-uuid', token: 'some-token'

      options =
        uri: '/user'
        baseUrl: "http://localhost:#{@serverPort}"
        qs:
          username: 'some-uuid'
          password: 'some-token'

      request.get options, (error, @response, @body) =>
        done error

    it 'should auth handler', ->
      @authDevice.done()

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200
      expect(@body).to.equal('allow')

    it 'should set the authorization in redis', (done) ->
      @client.exists 'some-uuid', (error, data) =>
        return done error if error?
        expect(data).to.equal 1
        done()

  describe 'GET /user (after authenticated)', ->
    beforeEach (done) ->
      @client.set 'some-uuid', new Date(), done

    afterEach (done) ->
      @client.del 'some-uuid', done

    beforeEach (done) ->
      options =
        uri: '/user'
        baseUrl: "http://localhost:#{@serverPort}"
        qs:
          username: 'some-uuid'

      request.get options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200
      expect(@body).to.equal('allow')

  describe 'when the service yields an error', ->
    beforeEach (done) ->
      userAuth = new Buffer('some-uuid:some-token').toString 'base64'

      @authDevice = @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{userAuth}"
        .reply 500, uuid: 'some-uuid', token: 'some-token'

      options =
        uri: '/user'
        baseUrl: "http://localhost:#{@serverPort}"
        qs:
          username: 'some-uuid'
          password: 'some-token'

      request.get options, (error, @response, @body) =>
        done error

    it 'should auth handler', ->
      @authDevice.done()

    it 'should return a 200 because ya', ->
      expect(@response.statusCode).to.equal 200
      expect(@body).to.equal('deny')
