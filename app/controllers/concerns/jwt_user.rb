module JWTUser
  extend ActiveSupport::Concern

  def jwt_user
    if token = request.headers['Authorization']
    token = token.match(/^Bearer\s+(.*)$/).captures.first
    claims = JWT.decode(token, env_credential('V4_JWT_KEY'), true, { algorithm: 'HS256' })
    v4_claims = claims.first
    return v4_claims.transform_keys! {|k| k.underscore.to_sym} || {}
    else
     nil
    end
  end
end