class V2::IvyRequestsController < ApplicationController
  def create
    ivy_request = V2::IvyRequest.new(ivy_request_params)
    if ivy_request.save
      render json: ivy_request.as_json, status: :created
    else
      render json: ivy_request.errors, status: :unprocessable_entity
    end
  end

  private

  def ivy_request_params
    params.require(:ivy_request).permit(:user_id, :library, :state, :catalog_id,
                                        :title, :volume, :edition, :author,
                                        items: [:barcode, :type, :call]
                                       )
  end

end
