class V4::MetadataController < V4ApplicationController

  def update_rights
    metadata = V4::Metadata.find(params[:id])
    response = {}
    status = :ok
    if metadata
      update_response = metadata.update_rights(rights_params)
      if !update_response.success?
        response = {error: update_response}
        status = :unprocessable_entity
      end
    else
      response = {error: "record not found"}
      status = :not_found
    end

    render json: response, status: status
  end

  private
  def rights_params
    params.permit(:resource_uri, :name, :uri, :statement)
  end
end