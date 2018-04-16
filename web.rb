require_relative 'login_service/sparql_queries.rb'

###
# Vocabularies
###

MU_ACCOUNT = RDF::Vocabulary.new(MU.to_uri.to_s + 'account/')
MU_SESSION = RDF::Vocabulary.new(MU.to_uri.to_s + 'session/')
BESLUIT =  RDF::Vocabulary.new('http://data.vlaanderen.be/ns/besluit#')

###
# POST /sessions
#
# Body
# data: {
#   relationships: {
#     account:{
#       data: {
#         id: "account_id",
#         type: "accounts"
#       }
#     }
#   },
#   type: "sessions"
# }
# Returns 201 on successful login
#         400 if session header is missing
#         400 on login failure (incorrect user/password or inactive account)
###
post '/sessions/' do
  content_type 'application/vnd.api+json'


  ###
  # Validate headers
  ###
  validate_json_api_content_type(request)

  session_uri = session_id_header(request)
  error('Session header is missing') if session_uri.nil?

  rewrite_url = rewrite_url_header(request)
  error('X-Rewrite-URL header is missing') if rewrite_url.nil?


  ###
  # Validate request
  ###

  data = @json_body['data']

  validate_resource_type('sessions', data)
  error('Id paramater is not allowed', 400) if not data['id'].nil?
  error('exactly one account should be linked') unless data.dig("relationships","account", "data", "id")
  error('exactly one group should be linked') unless data.dig("relationships","group", "data", "id")


  ###
  # Validate login
  ###

  result = select_account(data["relationships"]["account"]["data"]["id"])
  error('account not found.', 400) if result.empty?
  account = result.first

  result = select_group(data["relationships"]["group"]["data"]["id"])
  error('group not found', 400) if result.empty?
  group = result.first
  ###
  # Remove old sessions
  ###
  remove_old_sessions(session_uri)

  ###
  # Insert new session
  ###
  session_id = generate_uuid()
  insert_new_session_for_account(account[:uri].to_s, session_uri, session_id, group[:group].to_s)
  update_modified(session_uri)

  status 201
  {
    links: {
      self: rewrite_url.chomp('/') + '/current'
    },
    data: {
      type: 'sessions',
      id: session_id
    },
    relationships: {
      account: {
        links: {
          related: "/accounts/#{account[:uuid]}"
        },
        data: {
          type: "accounts",
          id: account[:uuid]
        }
      },
      group: {
        links: {
          related: "/bestuurseenheden/#{group[:uuid]}"
        },
        data: {
          type: "bestuurseenheden",
          id: group[:uuid]
        }
      }
    }
  }.to_json
end


###
# DELETE /sessions/current
#
# Returns 204 on successful logout
#         400 if session header is missing or session header is invalid
###
delete '/sessions/current/?' do
  content_type 'application/vnd.api+json'

  ###
  # Validate session
  ###

  session_uri = session_id_header(request)
  error('Session header is missing') if session_uri.nil?


  ###
  # Get account
  ### 

  result = select_account_by_session(session_uri)
  error('Invalid session') if result.empty?
  account = result.first[:account].to_s


  ###
  # Remove session
  ###

  result = select_current_session(account)
  result.each { |session| update_modified(session[:uri]) }
  delete_current_session(account)

  status 204
end


###
# GET /sessions/current
#
# Returns 204 if current session exists
#         400 if session header is missing or session header is invalid
###
get '/sessions/current/?' do
  content_type 'application/vnd.api+json'

  ###
  # Validate session
  ###

  session_uri = session_id_header(request)
  error('Session header is missing') if session_uri.nil?


  ###
  # Get account
  ###

  result = select_account_by_session(session_uri)
  error('Invalid session') if result.empty?
  account = result.first

  rewrite_url = rewrite_url_header(request)

  status 200
 {
    links: {
      self: rewrite_url.chomp('/')
    },
    data: {
      type: 'sessions',
      id: session_uri
    },
    relationships: {
      account: {
        links: {
          related: "/accounts/#{account[:uuid]}"
        },
        data: {
          type: "accounts",
          id: account[:uuid]
        }
      }
    }
  }.to_json
end


###
# Helpers
###

helpers LoginService::SparqlQueries
