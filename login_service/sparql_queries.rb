module LoginService
  module SparqlQueries
    def remove_old_sessions(session)
      query = " DELETE WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/sessions> {"
      query += "     <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                  <#{MU_CORE.uuid}> ?id ; "
      query += "                  <#{RDF::Vocab::DC.modified}> ?modified ; "
      query += "                  <#{MU_EXT.sessionRole}> ?role ;"
      query += "                  <#{MU_EXT.sessionGroup}> ?group ."
      query += "   }"
      query += " }"
      update(query)
    end

    def insert_new_session_for_account(account, session_uri, session_id, group_uri, group_id, roles)
      now = DateTime.now

      query =  " PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>"
      query += " INSERT DATA {"
      query += "   GRAPH <http://mu.semte.ch/graphs/sessions> {"
      query += "     <#{session_uri}> <#{MU_SESSION.account}> <#{account}> ;"
      query += "                      <#{RDF::Vocab::DC.modified}> #{now.sparql_escape} ;"
      query += "                      <#{MU_EXT.sessionGroup}> <#{group_uri}> ;"
      query += "                      <#{MU_CORE.uuid}> #{session_id.sparql_escape} ."
      roles.each do |role|
        query += "   <#{session_uri}> <#{MU_EXT.sessionRole}> #{role.sparql_escape} ."
      end
      query += "   }"
      query += " }"
      update(query)
    end

    def select_account_by_session(session)
      query =  " SELECT ?group_uuid ?account_uuid ?account WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/sessions> {"      
      query += "     <#{session}> <#{MU_SESSION.account}> ?account ;"
      query += "                  <#{MU_EXT.sessionGroup}> ?group ."
      query += "   }"
      query += "   GRAPH <http://mu.semte.ch/graphs/public> {"
      query += "     ?group a <#{BESLUIT.Bestuurseenheid}> ;"      
      query += "            <#{MU_CORE.uuid}> ?group_uuid ."
      query += "   }"
      query += "   GRAPH ?g {"
      query += "     ?account a <#{RDF::Vocab::FOAF.OnlineAccount}> ;"
      query += "              <#{MU_CORE.uuid}> ?account_uuid ."
      query += "   }"
      query += "   FILTER(?g = IRI(CONCAT(\"http://mu.semte.ch/graphs/organizations/\", ?group_uuid)))"
      query += " }"
      query(query)
    end

    def select_current_session(account)
      query =  " SELECT ?uri WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/sessions> {"      
      query += "     ?uri <#{MU_SESSION.account}> <#{account}> ;"
      query += "        <#{MU_CORE.uuid}> ?id . "
      query += "   }"
      query += " }"
      query(query)
    end

    def delete_current_session(account)
      query += " DELETE WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/sessions> {"
      query += "     ?session <#{MU_SESSION.account}> <#{account}> ;"
      query += "              <#{MU_CORE.uuid}> ?id ; "
      query += "              <#{RDF::Vocab::DC.modified}> ?modified ; "
      query += "              <#{MU_EXT.sessionRole}> ?role ;"
      query += "              <#{MU_EXT.sessionGroup}> ?group ."
      query += "   }"
      query += " }"
      update(query)
    end

    def select_account(id)
      query =  " SELECT ?uri WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/public> {"      
      query += "     ?group a <#{BESLUIT.Bestuurseenheid}> ;"      
      query += "            <#{MU_CORE.uuid}> ?group_uuid ."
      query += "   }"
      query += "   GRAPH ?g {"
      query += "     ?uri a <#{RDF::Vocab::FOAF.OnlineAccount}> ;"
      query += "          <#{MU_CORE.uuid}> \"#{id}\" ."
      query += "     ?person a <#{RDF::Vocab::FOAF.Person}> ;"
      query += "             <#{RDF::Vocab::FOAF.account}> ?uri ;"
      query += "             <#{RDF::Vocab::FOAF.member}> ?group ."
      query += "   }"
      query += "   BIND(IRI(CONCAT(\"http://mu.semte.ch/graphs/organizations/\", ?group_uuid)) as ?g)"
      query += " }"
      query(query)
    end

    def select_group(group_id)
      query =  " SELECT ?group WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/public> {"
      query += "      ?group a <#{BESLUIT.Bestuurseenheid}> ;"
      query += "               <#{MU_CORE.uuid}> \"#{group_id}\" ."
      query += "   }"
      query += " }"
      query(query)
    end


    def select_roles(account_id)
      query =  " SELECT ?role WHERE {"
      query += "   GRAPH <http://mu.semte.ch/graphs/public> {"      
      query += "     ?group a <#{BESLUIT.Bestuurseenheid}> ;"      
      query += "            <#{MU_CORE.uuid}> ?group_uuid ."
      query += "   }"
      query += "   GRAPH ?g {"
      query += "     ?uri a <#{RDF::Vocab::FOAF.OnlineAccount}> ;"
      query += "            <#{MU_CORE.uuid}> \"#{account_id}\" ;"
      query += "            <#{MU_EXT.sessionRole}> ?role ."
      query += "     ?person a <#{RDF::Vocab::FOAF.Person}> ;"
      query += "             <#{RDF::Vocab::FOAF.account}> ?uri ;"
      query += "             <#{RDF::Vocab::FOAF.member}> ?group ."
      query += "   }"
      query += "   BIND(IRI(CONCAT(\"http://mu.semte.ch/graphs/organizations/\", ?group_uuid)) as ?g)"
      query += " }"
      query(query)
    end
  end
end
