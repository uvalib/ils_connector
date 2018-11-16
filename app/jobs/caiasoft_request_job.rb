class CaiasoftRequestJob < ApplicationJob
  queue_as :default


  def perform(ivy_request)
    ivy_request.items.each do |item|
      response = HTTParty.post(
                    request_url(item['barcode'], 'PYR', ivy_request.library, item_details(item, ivy_request)),
        headers: caiasoft_headers
      )
      if response.success?
        # successful response, parse the body
        response = JSON.parse response.body

        if response['denied'] == 'Y'
          item.merge! 'errors' => response['status']
        else
          # attach success info
        end
      else

        item.merge! 'errors' => response.body
      end
    end
    if ivy_request.items.any? {|i| i.has_key? 'errors' }
      ivy_request.errored
    else
      ivy_request.request_sent
    end
    ivy_request.save
  end

  def request_url barcode, request_type, stop_code, details
    URI.encode "#{env_credential(:caiasoft_host)}/api/requestitem/v1/#{barcode}/#{request_type}/#{stop_code}/#{details}"
  end

  def caiasoft_headers
    @caiasoft_headers ||= {'X-API-Key' => env_credential(:caiasoft_api_key) }
  end

  def item_details item, ivy_request
    "Title: #{ivy_request.title}, User: #{ivy_request.user_id}, catalog_id: #{ivy_request.catalog_id}"
  end
end
