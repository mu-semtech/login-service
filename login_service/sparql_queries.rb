module LoginService
  module SparqlQueries
    def remove_old_sessions(session)
      query =  " WITH <#{settings.graph}> "
      query += " DELETE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                <#{MU_CORE.uuid}> ?id ; "
      query += "                <#{RDF::Vocab::DC.modified}> ?modified; "
      query += "                <#{MU_EXT.sessionGroup}> ?group ."
      query += " }"
      query += " WHERE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                <#{MU_CORE.uuid}> ?id ; "
      query += "                <#{RDF::Vocab::DC.modified}> ?modified; "
      query += "                <#{MU_EXT.sessionGroup}> ?group ."
      query += " }"
      update(query)
    end

    def insert_new_session_for_account(account, session_uri, session_id, group_uri)
      query =  " INSERT DATA {"
      query += "   GRAPH <#{settings.graph}> {"
      query += "     <#{session_uri}> <#{MU_SESSION.account}> <#{account}> ;"
      query += "                      <#{MU_EXT.sessionGroup}> <#{group_uri}> ;"
      query += "                      <#{MU_CORE.uuid}> #{session_id.sparql_escape} ."
      query += "   }"
      query += " }"
      update(query)
    end

    def select_group(group_id)
      query =  " SELECT ?group FROM <#{settings.graph}> WHERE {"
      query += "  ?group a <#{BESLUIT.Bestuurseenheid}> ;"
      query += "              <#{MU_CORE.uuid}> \"#{group_id}\" ."
      query += " }"
      query(query)
    end

    def select_account_by_session(session)
      query =  " SELECT ?group_uuid ?account_uuid ?account FROM <#{settings.graph}> WHERE {"
      query += "   <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                <#{MU_EXT.sessionGroup}> ?group ."
      query += "   ?group <#{MU_CORE.uuid}> ?group_uuid ."
      query += "   ?account <#{MU_CORE.uuid}> ?account_uuid ."
      query += "   ?account a <#{RDF::Vocab::FOAF.OnlineAccount}> ."
      query += " }"
      query(query)
    end

    def select_current_session(account)
      query =  " SELECT ?uri FROM <#{settings.graph}> WHERE {"
      query += "   ?uri <#{MU_SESSION.account}> <#{account}> ;"
      query += "        <#{MU_CORE.uuid}> ?id ; "
      query += "        <#{MU_EXT.sessionGroup}> ?group ."
      query += " }"
      query(query)
    end

    def delete_current_session(account)
      query =  " WITH <#{settings.graph}> "
      query += " DELETE {"
      query += "   ?session <#{MU_SESSION.account}> <#{account}> ;"
      query += "            <#{MU_CORE.uuid}> ?id ; "
      query += "            <#{MU_EXT.sessionGroup}> ?group ."
      query += " }"
      query += " WHERE {"
      query += "   ?session <#{MU_SESSION.account}> <#{account}> ;"
      query += "            <#{MU_CORE.uuid}> ?id ; "
      query += "            <#{MU_EXT.sessionGroup}> ?group ."
      query += " }"
      update(query)
    end

    def select_account(id)
      query =  " SELECT ?uri FROM <#{settings.graph}> WHERE {"
      query += "   ?uri <#{MU_CORE.uuid}> \"#{id}\" ."
      query += "   ?uri a <#{RDF::Vocab::FOAF.OnlineAccount}> ."
      query += " }"
      query(query)
    end
  end
end
