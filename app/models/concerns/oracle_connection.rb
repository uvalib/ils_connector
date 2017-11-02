module OracleConnection
  extend ActiveSupport::Concern

  included do
    establish_connection :oracle_default

    self.primary_key = 'id'
  end

end
