class DownloadsController <ApplicationController
  def download
    id = params[:chart_id]
    send_file(
      "#{Rails.root}/public/downloads/#{id}.pdf",
      filename: "#{id}.pdf",
      type: "application/pdf"
    )
  end
end
