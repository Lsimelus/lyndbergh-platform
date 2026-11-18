# POST /api/feedback: a product's feedback button (Real Calc, ABChealth).
module Api
  class FeedbackController < SubmissionsController
    def create
      submit Feedback.new(params.permit(:site, :rating, :comment, :page, :user_ref, :email)), event: "feedback_submitted"
    end
  end
end
