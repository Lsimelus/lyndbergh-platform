# POST /api/contact-form: the Portfolio's contact form (same fields it sends today).
module Api
  class ContactMessagesController < SubmissionsController
    def create
      submit ContactMessage.new(params.permit(:site, :name, :email, :subject, :message)), event: "contact_submitted"
    end
  end
end
