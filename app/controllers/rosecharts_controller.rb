class RosechartsController < ApplicationController
  def upload
    uploaded_file = params[:gedcom]
    # disk_file = File.open(Rails.root.join('public', 'uploads', uploaded_file.original_filename), 'wb') do |file|
    #   file.write(uploaded_file.read)
    # end
    pdf = RosePdfCreator.new(uploaded_file.tempfile, 5).generate_pdf
    send_data pdf, :filename => "public/downloads/Test2.pdf", :type => "pdf"
  end

end
