require 'sinatra'
require 'sparql/client'
require 'json'
require 'bcrypt'

configure do
  set :graph, 'http://mu.semte.ch/app' 
  set :sparql_client, SPARQL::Client.new('http://localhost:8890/sparql') 
end

post '/login' do
  content_type :json

  session_uri = request.env['HTTP_MU_SESSION_ID']
  halt 400, { error: 'Session header is missing' }.to_json if session_uri.nil?
  # TODO validate if session isn't already associated with a user

  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  query =  " PREFIX mu: <http://mu.semte.ch#>"
  query += " PREFIX foaf: <http://xmlns.com/foaf/0.1/>"
  query += " SELECT ?account ?password ?salt FROM <#{settings.graph}> WHERE {"
  query += " ?account a foaf:Account ;"
  query += "          foaf:accountName '#{data['accountName'].downcase}' ; "
  query += "          mu:password ?password ; "
  query += "          mu:salt ?salt . "
  query += " }"
  result = settings.sparql_client.query query

  halt 401 if result.empty?

  account = result.first
  db_password = BCrypt::Password.new(account[:password].to_s)

  halt 401 unless db_password == data['password']

  query =  " INSERT DATA {"
  query += "   GRAPH <#{settings.graph}> {"
  query += "     <#{session_uri}> <http://mu.semte.ch#session/account> <#{account[:account].to_s}> ."
  query += "   }"
  query += " }"
  settings.sparql_client.update(query)
  # TODO remove old sessions

  status 200
end

post '/logout' do
  content_type :json
  # TODO implement
end
