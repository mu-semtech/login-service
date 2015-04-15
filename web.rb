require 'sinatra'
require 'sparql/client'
require 'json'
require 'digest'

configure do
  set :salt, ENV['MU_APPLICATION_SALT']
  set :graph, ENV['MU_APPLICATION_GRAPH']
  set :sparql_client, SPARQL::Client.new('http://database:8890/sparql') 
end


###
# Vocabularies
###

include RDF
MU = RDF::Vocabulary.new('http://mu.semte.ch/vocabulary/')


###
# POST /login
#
# Body    { "nickname": "john_doe", "password": "secret" }
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
  halt 400, { errors: { title: 'Session header is missing' } }.to_json if session_uri.nil?


  ###
  # Validate login
  ###

  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  query =  " SELECT ?uri ?password ?salt FROM <#{settings.graph}> WHERE {"
  query += "   ?uri a <#{FOAF.OnlineAccount}> ;"
  query += "        <#{FOAF.accountName}> '#{data['nickname'].downcase}' ; "
  query += "        <#{MU['account/password']}> ?password ; "
  query += "        <#{MU['account/salt']}> ?salt . "
  query += " }"
  result = settings.sparql_client.query query

  halt 401 if result.empty?
 
  account = result.first
  db_password = account[:password].to_s
  password = Digest::MD5.new << data['password'] + settings.salt + account[:salt].to_s

  halt 401 unless db_password == password.hexdigest


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


###
# POST /logout
#
# Returns 200 on successful logout
#         400 if session header is missing or session header is invalid
###
post '/logout' do
  content_type :json

  ###
  # Validate session
  ###

  session_uri = request.env['HTTP_MU_SESSION_ID']
  halt 400, { errors: { title: 'Session header is missing' } }.to_json if session_uri.nil?


  ###
  # Get account
  ### 
  query =  " SELECT ?account FROM <#{settings.graph}> WHERE {"
  query += "   <#{session_uri}> <#{MU['session/account']}> ?account ."
  query += "   ?account a <#{FOAF.OnlineAccount}> ."
  query += " }"
  result = settings.sparql_client.query query

  halt 400, { errors: { title: 'Invalid session' } }.to_json if result.empty?

  account = result.first[:account].to_s


  ###
  # Remove session
  ###

  query =  " WITH <#{settings.graph}> "
  query += " DELETE {"
  query += "   ?session <#{MU['session/account']}> <#{account}> ."
  query += " }"
  query += " WHERE {"
  query += "   ?session <#{MU['session/account']}> <#{account}> ."
  query += " }"
  settings.sparql_client.update(query)

  status 200
end
