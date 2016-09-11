require 'theoldreader/api/version'
require 'faraday'
require 'multi_json'

module Theoldreader
  class Api #:nodoc:
    HOST = 'theoldreader.com'
    BASE_PATH = '/reader/api/0/'
    ENDPOINTS = {
      'accounts/ClientLogin' => { method: 'post', params: %w(client Email Passwd), default_params: { accountType: 'HOSTED_OR_GOOGLE', service: 'reader' }},
      'status' => { method: 'get' },
      'token' => { method: 'get' },
      'user-info' => { method: 'get' },
      'preference/list' => { method: 'get' },
      'friend/list' => { method: 'get' },
      'friend/edit' => { method: 'post', params: %w(action u) },
      'comment/edit' => { method: 'post', params: %w(action i comment) },
      'tag/list' => { method: 'get' },
      'preference/stream/list' => { method: 'get' },
      'preference/stream/set' => { method: 'post' },
      'rename-tag' => { method: 'post', params: %w(s dest) },
      'disable-tag' => { method: 'post', params: %w(s) },
      'unread-count' => { method: 'get' },
      'subscription/list' => { method: 'get' },
      'subscription/quickadd' => { method: 'post', params: %w(quickadd) },
      'subscription/edit' => { method: 'post', params: %w(ac s t a r) },
      'stream/items/ids' => { method: 'get', params: %w(s xt n r c nt ot) },
      'stream/items/contents' => { method: 'post', params: %w(i output) },
      'stream/contents' => { method: 'get', params: %w(s xt n r c nt ot output) },
      'mark-all-as-read' => { method: 'post', params: %w(s ts) },
      'edit-tag' => { method: 'post', params: %w(i a r annotation) },
      '/reader/subscriptions/export' => { method: 'get' },
      '/reader/atom' => { method: 'get' }
    }.freeze

    attr_accessor :token, :http_options

    def initialize(token = nil, http_options = {})
      @token = token
      @http_options = http_options
    end

    def call(endpoint, params = {}, headers = {})
      fail Exceptions::WrongEndpoint unless ENDPOINTS.keys.include?(endpoint)
      response = conn.send(
        ENDPOINTS[endpoint][:method],
        base_path_for(endpoint),
        default_params(endpoint).merge(sanitize_params(endpoint, params)),
        auth_header.merge(headers)
      )
      handle_erros(response)
      prepare_response(response)
    end

    private

    def conn
      @conn ||= Faraday.new(url: "#{protocol}://#{HOST}") do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def protocol
      http_options[:use_ssl] == false ? 'http' : 'https'
    end

    def base_path_for(endpoint)
      (endpoint.start_with?('/') ? '' : BASE_PATH) + endpoint
    end

    def default_params(endpoint)
      { output: 'json' }.merge(ENDPOINTS[endpoint][:default_params] || {})
    end

    def sanitize_params(endpoint, params)
      return params unless ENDPOINTS[endpoint][:params]
      params.delete_if do |key, _|
        !ENDPOINTS[endpoint][:params].include?(key.to_s)
      end
    end

    def handle_erros(response)
      fail(
        Exceptions::ResponseError.new(response),
        'Theoldreader API has returned the error'
      ) unless response.status == 200
    end

    def prepare_response(response)
      MultiJson.load(response.body.to_s)
    rescue MultiJson::LoadError
      response.body
    end

    def auth_header
      token.nil? ? {} : { 'Authorization' => "GoogleLogin auth=#{token}" }
    end
  end

  module Exceptions
    class ResponseError < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def to_s
        super + format(' (%s)', data.map { |k, v| %(#{k}: "#{v}") }.join(', '))
      end

      private

      def data
        @data ||= begin
          MultiJson.load(response.body)
        rescue MultiJson::DecodeError
          { uri: response.env.url.to_s, errors: response.body.to_s }
        end.merge(code: response.status)
      end
    end
    class WrongEndpoint < StandardError
    end
  end
end
