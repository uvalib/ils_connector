class V2::CircRecord < SirsiBase

  def self.find id
    ensure_login do
      response = get("/circulation/circRecord/key/#{id}",
                      headers: self.auth_headers,
                      max_retries: 0
                    )
      check_session(response)
      response.parsed_body

    end
  end
end
