class V4::Location < SirsiBase

  include ActiveModel::Serializers::JSON
  include Refreshable
  include AvailabilityHelper
  base_uri env_credential(:sirsi_web_services_base)
  LOCATION_PARAMS = {key: '*', includeFields: 'key,policyNumber,description,shadowed'}

  attr_accessor :id, :key, :description, :on_shelf, :online, :unavailable, :shadowed, :non_circulating

  # for serializer root node
  def self.model_name
    'location'
  end

  def self.all
    @@locations = nil if time_to_refresh?
    @@locations ||= get_locations
  end

  def self.find key
    all.find do |loc|
      loc.key == key
    end
  end

  def self.medium_rare? key
    match? key, MEDIUM_RARE_LOCATIONS
  end

  def circulating
    !self.non_circulating
  end

  private
  def self.get_locations
    ensure_login do
      response = get('/policy/location/simpleQuery',
                      query: LOCATION_PARAMS,
                      headers: auth_headers,
                      max_retries: 0
                     )
      check_session(response)

      processed_locations = response.parsed_response.map do |resource|
        loc = V4::Location.new
        loc.id = resource['fields']['policyNumber']
        loc.key = resource['key']
        loc.description = resource['fields']['description']
        loc.on_shelf = AvailabilityHelper.on_shelf_location? loc.key
        loc.non_circulating = AvailabilityHelper.non_circulating_location? loc.key
        loc.online = match?(loc.key, ONLINE_LOCATIONS)
        loc.unavailable = match?(loc.key, UNAVAILABLE_LOCATIONS)
        loc.shadowed = resource['fields']['shadowed']
        loc
      end
      reset_refresh_timer
      processed_locations
    end
  end

  # Generate a list of String and/or Regexp against which a code value can be
  # matched.
  #
  # @param [Array<String, Regexp, Array>] args
  #
  # @return [Array<String, Regexp>]
  #
  def self.codes(*args)
    args.flatten.map { |arg|
      arg.is_a?(Regexp) ? Regexp.new(arg.source, Regexp::IGNORECASE) : arg.to_s
    }.reject(&:blank?).freeze
  end

  # Match a library code or location code against one or more patterns.
  #
  # If *code* is a Symbol, it is translated; e.g. :mt_lake becomes 'MT-LAKE'.
  #
  # @param [String, Symbol]               code
  # @param [Array<String, Regexp, Array>] args
  #
  def self.match?(code, *args)
    code = code.to_s.dasherize.upcase
    args.flatten.any? { |arg| code.match?(arg) }
  end

  ONLINE_LOCATIONS = codes('INTERNET', 'NOTOREPDA')

  # Unavailable now means that an item is not on shelf nor holdable for anyone
  # These are still shown for now.
  UNAVAILABLE_LOCATIONS =
    codes(/LOST/, <<-HEREDOC.squish.split)
       UNKNOWN
       MISSING
       DISCARD
       WITHDRAWN
       BARRED
       BURSARED
       ORD-CANCLD
     HEREDOC


  HOLD_LOCATIONS      = codes /HOLD/
  RESERVE_LOCATIONS   = codes /RESV/, /RSRV/, /RESERVE/, 'PATFAMCOLL'
  REFERENCE_LOCATIONS = codes /REF/,  'FA-SLIDERF'
  DESK_LOCATIONS      = codes /DESK/, 'SERV-DSK'
  NON_CIRC_LOCATIONS  = (REFERENCE_LOCATIONS + DESK_LOCATIONS).freeze
  IVY = codes /IVY/

  # V3 Unavailable means not available to be checked out
  # These are now basically "by request"
  V3_UNAVAILABLE_LOCATIONS =
    codes(HOLD_LOCATIONS,  <<-HEREDOC.squish.split)
       CHECKEDOUT
       ON-ORDER
       BINDERY
       INTRANSIT
       ILL
       CATALOGING
       PRESERVATN
       EXHIBIT
       GBP
       RENO-PAUSE
    HEREDOC

  BY_REQUEST_LOCATIONS =
    codes <<-HEREDOC.squish.split
            BY-REQUEST
            CLEM-CONST
            TRAN-2-CL
            TRAN-2-IVY
  HEREDOC

  # @see Firehose::Copy#medium_rare?
  MEDIUM_RARE_LOCATIONS = codes 'LOCKEDSTKS'
  MEDIUM_RARE_MESSAGE = "This item is medium rare and does not circulate. When you request this item from Ivy, it will be delivered to the Small Special Collections Library for you to use in the reading room only."

  # Libraries that do not have checkout (for UVA persons).
  RESERVE_LIBRARIES = codes %w(SPEC-COLL JAG)

  # Libraries that are too far away to be part of LEO delivery.
  REMOTE_LIBRARIES = codes %w(BLANDY MT-LAKE AT-SEA INTERNET)

  # Libraries from which LEO cannot deliver.
  NON_LEO_LIBRARIES = (RESERVE_LIBRARIES + REMOTE_LIBRARIES).freeze

  NOT_ON_SHELF = UNAVAILABLE_LOCATIONS + V3_UNAVAILABLE_LOCATIONS +
    RESERVE_LOCATIONS + NON_CIRC_LOCATIONS +
    RESERVE_LIBRARIES + MEDIUM_RARE_LOCATIONS +
    REMOTE_LIBRARIES + BY_REQUEST_LOCATIONS + IVY
end
