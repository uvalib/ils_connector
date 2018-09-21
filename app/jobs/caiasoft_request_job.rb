class CaiasoftRequestJob < ApplicationJob
  queue_as :default


  def perform(ivy_request)
    ivy_request.items.each do |item|
      response = HTTParty.get(
                    request_url(item['barcode'], 'PYR', ivy_request.library, item_details(item, ivy_request)),
        headers: caiasoft_headers
      )
      if response.success?
        # 
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
    URI.encode "#{ENV['CAIASOFT_HOST']}/api/requestitem/v1/#{barcode}/#{request_type}/#{stop_code}/#{details}"
  end

  def caiasoft_headers
    @caiasoft_headers ||= {'X-API-Key' => ENV['CAIASOFT_API_KEY']}
  end

  def item_details item, ivy_request
    "Title: #{ivy_request.title}, User: #{ivy_request.user_id}, catalog_id: #{ivy_request.catalog_id}"
  end
end
