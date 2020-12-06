require 'sparql/client'

module Mu
  module AuthSudo
    module Helpers
      def self.included(base)
        define_method(:query_sudo) { |query| Mu::AuthSudo.query(query) }
        define_method(:update_sudo) { |query| Mu::AuthSudo.update(query) }
      end
    end

    def self.sparql_client(options = {})
      options = { headers: { 'mu-auth-sudo': 'true' } }
      if ENV['MU_SPARQL_TIMEOUT']
        options[:read_timeout] = ENV['MU_SPARQL_TIMEOUT'].to_i
      end
      SPARQL::Client.new(ENV['MU_SPARQL_ENDPOINT'], options)
    end

    def self.query(query)
      puts "Executing sudo query: #{query}"
      sparql_client.query query
    end

    def self.update(query)
      puts "Executing sudo update: #{query}"
      sparql_client.update query
    end
  end
end
