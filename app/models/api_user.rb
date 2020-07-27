# NOT USED
class ApiUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # More info on devise-jwt: https://github.com/waiting-for-dev/devise-jwt
  include Devise::JWT::RevocationStrategies::JTIMatcher
  devise :database_authenticatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
end
