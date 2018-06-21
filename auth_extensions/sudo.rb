module AuthExtensions
  module Sudo
    def sparql_client
      log.info('Create sudo SPARQL client')
      if @sparql_client.nil?
        options = {
          headers: { 'mu-auth-sudo': 'true' }
        }
        if ENV['MU_SPARQL_TIMEOUT']
          options[:read_timeout] = ENV['MU_SPARQL_TIMEOUT'].to_i
        end
        @sparql_client = SPARQL::Client.new(ENV['MU_SPARQL_ENDPOINT'], options)
      end
      @sparql_client
    end
  end
end
