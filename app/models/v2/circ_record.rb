class V2::CircRecord < SirsiBase

  def self.find id
    ensure_login do
      response = get("/v1/circulation/circRecord/key/#{id}",
                      headers: self.auth_headers
                    )
      response.parsed_body

    end
  end
end
