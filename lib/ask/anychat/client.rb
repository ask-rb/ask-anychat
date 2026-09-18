# frozen_string_literal: true

require "erb"
require "faraday"
require "faraday/retry"
require "ask/auth"

module Ask
  module AnyChat
    # A client for the Anychat API.
    #
    # Every call names a workspace, because a workspace is what a token reaches:
    # the API resolves it through the token's user, so a token sees only the
    # workspaces its user belongs to. Naming somebody else's workspace is the
    # same answer as naming one that does not exist, which is the point.
    #
    #   client = Ask::AnyChat.client(base_url: "https://anywaye.com", token: "...")
    #   client.workspace_agents("anywaye")
    #
    # Failures raise under Error, carrying the sentence the API answered with.
    class Client
      RETRY_STATUSES = [429, 500, 502, 503].freeze
      OPEN_TIMEOUT = 10

      attr_reader :base_url

      def initialize(base_url:, token:, timeout: 30)
        @base_url = normalize(base_url)
        @token = token
        @timeout = timeout
      end

      # The agents a workspace owns, oldest first.
      def workspace_agents(workspace)
        fetch_key(get(agents_path(workspace)), "agents")
      end

      # One agent, by the address it answers on.
      def workspace_agent(workspace, handle)
        fetch_key(get("#{agents_path(workspace)}/#{encode(handle)}"), "agent")
      end

      def create_workspace_agent(workspace, **attributes)
        fetch_key(post(agents_path(workspace), agent: attributes), "agent")
      end

      def update_workspace_agent(workspace, handle, **attributes)
        fetch_key(patch("#{agents_path(workspace)}/#{encode(handle)}", agent: attributes), "agent")
      end

      # An address the owner printed is the reason they care about this one, so
      # it is gone afterwards and free for the next agent to take. Nothing comes
      # back but the fact that it worked; a failure raises.
      def destroy_workspace_agent(workspace, handle)
        delete("#{agents_path(workspace)}/#{encode(handle)}")
      end

      # -- sources -----------------------------------------------------------

      # The sources an agent may read, oldest first.
      def agent_sources(workspace, agent)
        fetch_key(get(sources_path(workspace, agent)), "sources")
      end

      # One source, by the handle list_sources returns.
      def agent_source(workspace, agent, source)
        fetch_key(get("#{sources_path(workspace, agent)}/#{encode(source)}"), "source")
      end

      # Every page this agent may read in a source — the manifest.
      def agent_source_pages(workspace, agent, source)
        fetch_key(get("#{sources_path(workspace, agent)}/#{encode(source)}/pages"), "pages")
      end

      # One page, as clean markdown, from the plane or from the website itself
      # when the plane has nothing. Returns the full page hash with title,
      # content, and source keys.
      def agent_source_page(workspace, agent, source, reference)
        get("#{sources_path(workspace, agent)}/#{encode(source)}/pages#{reference}")
      end

      # Search the pages an agent may read within a source.
      def agent_source_search(workspace, agent, source, query)
        fetch_key(
          get("#{sources_path(workspace, agent)}/#{encode(source)}/search", q: query),
          "results"
        )
      end

      # The headers every request carries. Public because it is the honest
      # answer to "what does this client send?" — and because a caller swapping
      # the connection under it should be able to keep them.
      def default_headers
        {
          "Authorization" => "Bearer #{token}",
          "Accept" => "application/json",
          "User-Agent" => "ask-anychat/#{VERSION}"
        }
      end

      private

      attr_reader :token, :timeout

      def agents_path(workspace)
        "/api/#{API_VERSION}/workspaces/#{encode(workspace)}/agents"
      end

      def sources_path(workspace, agent)
        "#{agents_path(workspace)}/#{encode(agent)}/sources"
      end

      def get(path, params = nil)
        request(:get, path, params: params)
      end

      def post(path, body = nil)
        request(:post, path, body: body)
      end

      def patch(path, body = nil)
        request(:patch, path, body: body)
      end

      def delete(path)
        request(:delete, path)
      end

      def request(method, path, body: nil, params: nil)
        response = connection.public_send(method, path) do |request|
          request.params = params if params
          request.body = body if body
        end

        response.success? ? parse(response) : raise_for(response)
      rescue Faraday::Error => e
        raise Error::Unreachable, "#{base_url} could not be reached: #{e.message}"
      end

      def connection
        @connection ||= Faraday.new(url: base_url, headers: default_headers) do |builder|
          builder.request :json
          builder.response :json, content_type: /\bjson$/
          builder.request :retry, max: 3, retry_statuses: RETRY_STATUSES, interval: 0.5
          builder.options.timeout = timeout
          builder.options.open_timeout = OPEN_TIMEOUT
          builder.adapter Faraday.default_adapter
        end
      end

      # A body is an object, or nothing at all — a 204 has nothing to read. A
      # body that is neither is the API answering with something this gem does
      # not know what to do with, which is worth saying out loud.
      def parse(response)
        body = response.body
        return {} if body.nil? || (body.is_a?(String) && body.strip.empty?)
        return body if body.is_a?(Hash)

        raise Error::Api, "the API answered with #{body.class} where an object was expected"
      end

      def raise_for(response)
        message = message_from(response)

        case response.status
        when 401 then raise Error::Unauthorized, message
        when 404 then raise Error::NotFound, message
        when 422 then raise Error::Invalid, message
        else raise Error::Api, "HTTP #{response.status} from #{base_url}: #{message}"
        end
      end

      # A failure is answered as {"error" => "..."} and sometimes with a
      # field-by-field map beside it. The sentence is what a person reads, so it
      # is preferred over the map and over the status code.
      def message_from(response)
        body = response.body
        return body.to_s unless body.is_a?(Hash)

        sentence = body["error"].to_s.strip
        return sentence unless sentence.empty?
        return body["errors"].to_s if body["errors"]

        "the request was refused"
      end

      def fetch_key(body, key)
        body.fetch(key) { raise Error::Api, "the API answered without #{key.inspect}: #{body.inspect}" }
      end

      def encode(segment)
        ERB::Util.url_encode(segment.to_s)
      end

      def normalize(url)
        url.to_s.sub(%r{/+\z}, "")
      end
    end
  end
end
