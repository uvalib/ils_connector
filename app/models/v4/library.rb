class V4::Library < SirsiBase
  # V2 Library uses a yml file
  # V4 should try to move away from that as much as possible
  include Refreshable
  base_uri env_credential(:sirsi_web_services_base)
  LIBRARY_PARAMS = {key: '*', includeFields: 'policyNumber,description'}

  attr_accessor :id, :key, :description, :on_shelf, :holdable, :remote, :deliverable, :course_reserve

  NON_HOLDABLE = %w(UVA-LIB SPEC_COLL EDUCATION MT-LAKE BLANDY LEO)
  NON_DELIVERABLE =  %w(UVA-LIB SPEC_COLL EDUCATION IVY MT-LAKE BLANDY MEDIA-CTR)
  REMOTE = %w(SPEC_COLL MT-LAKE BLANDY)
  COURSE_RESERVE = %(ASTRONOMY SCI-ENG MATH CLEMONS FINE-ARTS LAW MUSIC PHYSICS)

  NOT_ON_SHELF = %w(SPEC_COLL)

  def self.all
    @@libraries = nil if time_to_refresh?
    @@libraries ||= get_libraries
  end

  def self.find key
    all.find do |lib|
      lib.key == key
    end
  end

  private
  def self.get_libraries
    ensure_login do
      response = get('/v1/policy/library/simpleQuery',
                      query: LIBRARY_PARAMS,
                      headers: auth_headers
                     )
      check_session(response)

      processed_libraries = response.parsed_response.map do |resource|
        lib = V4::Library.new
        lib.id = resource['fields']['policyNumber']
        lib.key = resource['key']
        lib.description = resource['fields']['description']
        lib.holdable = !NON_HOLDABLE.include?(lib.key)
        lib.deliverable = !NON_DELIVERABLE.include?(lib.key)
        lib.remote = REMOTE.include?(lib.key)
        lib.on_shelf = !NOT_ON_SHELF.include?(lib.key)
        lib.course_reserve = COURSE_RESERVE.include?(lib.key)
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

end
