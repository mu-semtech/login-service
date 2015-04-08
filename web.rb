require 'sinatra'
require 'sparql/client'
require 'json'
require 'bcrypt'

configure do
  set :graph, 'http://mu.semte.ch/app' 
  set :sparql_client, SPARQL::Client.new('http://localhost:8890/sparql') 
end


###
# Vocabularies
###

include RDF
MU = RDF::Vocabulary.new('http://mu.semte.ch#')


###
# POST /login
#
# Body    { "accountName": "john_doe", "password": "secret" }
# Returns 200 on successful login
#         400 if session header is missing
#         401 on login failure
###
post '/login' do
  content_type :json


  ###
  # Validate session
  ###

  session_uri = request.env['HTTP_MU_SESSION_ID']
  halt 400, { error: 'Session header is missing' }.to_json if session_uri.nil?
  # TODO validate if session isn't already associated with a user


  ###
  # Validate login
  ###

  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  query =k " SELECT ?uri ?password ?salt FROM <#{settings.graph}> WHERE {"
  query += " ?uri a <#{FOAF.OnlineAccount}> ;"
  query += "        <#{FOAF.accountName}> '#{data['accountName'].downcase}' ; "
  query += "        <#{MU.password}> ?password ; "
  query += "        <#{MU.salt}> ?salt . "
  query += " }"
  result = settings.sparql_client.query query

  halt 401 if result.empty?

  account = result.first
  db_password = BCrypt::Password.new(account[:password].to_s)

  halt 401 unless db_password == data['password']


  ###
  # Remove old sessions
  ###

  query =  " WITH <#{settings.graph}> "
  query += " DELETE {"
  query += "   ?session <#{MU['session/account']}> <#{account[:uri].to_s}> ."
  query += " }"
  query += " WHERE {"
  query += "   ?session <#{MU['session/account']}> <#{account[:uri].to_s}> ."
  query += " }"
  settings.sparql_client.update(query)


  ###
  # Insert new session
  ###

  query =  " INSERT DATA {"
  query += "   GRAPH <#{settings.graph}> {"
  query += "     <#{session_uri}> <#{MU['session/account']}> <#{account[:uri].to_s}> ."
  query += "   }"
  query += " }"
  settings.sparql_client.update(query)

  status 200
end

post '/logout' do
  content_type :json
  # TODO implement
end
