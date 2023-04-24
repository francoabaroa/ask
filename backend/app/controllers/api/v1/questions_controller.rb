module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        # Your logic goes here
        render json: { message: "Your response" }
      end
    end
  end
end
