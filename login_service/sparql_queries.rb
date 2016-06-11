module LoginService
  module SparqlQueries

    def select_salted_password_and_salt_by_nickname(nickname)
      query =  " SELECT ?uuid ?uri ?password ?salt FROM <#{settings.graph}> WHERE {"
      query += "   ?uri a <#{RDF::Vocab::FOAF.OnlineAccount}> ; "
      query += "        <#{RDF::Vocab::FOAF.accountName}> #{nickname.downcase.sparql_escape} ; "
      query += "        <#{MU_ACCOUNT.status}> <#{MU_ACCOUNT['status/active']}> ; "
      query += "        <#{MU_ACCOUNT.password}> ?password ; "
      query += "        <#{MU_ACCOUNT.salt}> ?salt ; "
      query += "        <#{MU_CORE.uuid}> ?uuid"
      query += " }"
      query(query)
    end

    def remove_old_sessions(session)
      query =  " WITH <#{settings.graph}> "
      query += " DELETE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                <#{MU_CORE.uuid}> ?id . "
      query += " }"
      query += " WHERE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                <#{MU_CORE.uuid}> ?id . "
      query += " }"
      update(query)
    end

    def insert_new_session_for_account(account, session_uri, session_id)
      query =  " INSERT DATA {"
      query += "   GRAPH <#{settings.graph}> {"
      query += "     <#{session_uri}> <#{MU_SESSION.account}> <#{account}> ;"
      query += "                      <#{MU_CORE.uuid}> #{session_id.sparql_escape} ."
      query += "   }"
      query += " }"
      update(query)
    end
    
    def select_account_by_session(session)
      query =  " SELECT ?uuid ?account FROM <#{settings.graph}> WHERE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ."
      query += "   ?account <#{MU_CORE.uuid}> ?uuid ."
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ."
      query += "   ?account a <#{RDF::Vocab::FOAF.OnlineAccount}> ."
      query += " }"
      query(query)
    end
    
    def select_current_session(account)
      query =  " SELECT ?uri FROM <#{settings.graph}> WHERE {"
      query += "   ?uri <#{MU_SESSION.account}> <#{account}> ;"
      query += "        <#{MU_CORE.uuid}> ?id . "
      query += " }"
      query(query)
    end

    def delete_current_session(account)
      query =  " WITH <#{settings.graph}> "
      query += " DELETE {"
      query += "   ?session <#{MU_SESSION.account}> <#{account}> ;"
      query += "            <#{MU_CORE.uuid}> ?id . "
      query += " }"
      query += " WHERE {"
      query += "   ?session <#{MU_SESSION.account}> <#{account}> ;"
      query += "            <#{MU_CORE.uuid}> ?id . "
      query += " }"
      update(query)
    end

  end
end
