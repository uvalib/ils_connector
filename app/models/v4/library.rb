# Library from Sirsi's API
class V4::Library < SirsiBase
  include Refreshable
  include ActiveModel::Serializers::JSON
  include AvailabilityHelper
  base_uri env_credential(:sirsi_web_services_base)
  LIBRARY_PARAMS = {key: '*', includeFields: 'policyNumber,description'}

  attr_accessor :id, :key, :description, :on_shelf, :non_circulating

  # for serializer root node
  def self.model_name
    'library'
  end

  def self.all
    @@libraries = nil if time_to_refresh?
    @@libraries ||= get_libraries
  end

  def self.find key
    all.find do |lib|
      lib.key == key
    end
  end

  def circulating
    !self.non_circulating
  end

  private
  def self.get_libraries
    ensure_login do
      response = get('/policy/library/simpleQuery',
                      query: LIBRARY_PARAMS,
                      headers: auth_headers,
                      max_retries: 0
                     )
      check_session(response)

      processed_libraries = response.parsed_response.map do |resource|
        lib = V4::Library.new
        lib.id = resource['fields']['policyNumber']
        lib.key = resource['key']
        lib.description = resource['fields']['description']
        lib.on_shelf = AvailabilityHelper.on_shelf_library? lib.key
        lib.non_circulating = AvailabilityHelper.non_circulating_library? lib.key
        lib
      end
      reset_refresh_timer
      processed_libraries
    end
  end


  # TODO
  # Libraries that should come after others in the availability list and in
  # summary holdings.
  #
  # @see Firehose::Common#later_libraries
  #
  LATER_LIBRARY = {
    jag:      'JAG School',
    ivy:      'Ivy Stacks',
    blandy:   'Blandy Experimental Farm',
    mt_lake:  'Mountain Lake',
    at_sea:   'Semester at Sea',
  }.freeze

  # From Virgo 3. possibly useful for requests
  #NON_HOLDABLE = %w(UVA-LIB SPEC_COLL EDUCATION MT-LAKE BLANDY LEO)
  #NON_DELIVERABLE =  %w(UVA-LIB SPEC_COLL EDUCATION IVY MT-LAKE BLANDY MEDIA-CTR)
  #REMOTE = %w(SPEC_COLL MT-LAKE BLANDY)
  #COURSE_RESERVE = %(ASTRONOMY SCI-ENG MATH CLEMONS FINE-ARTS LAW MUSIC PHYSICS)

end
