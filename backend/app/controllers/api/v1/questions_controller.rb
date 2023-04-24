module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        question = params[:question]

        # Temporary for testing
        answer = question

        render json: { answer: question }
      end

      private

      def search_book_embeddings(question)
        # Implementation
      end

      def cache_answer(question, answer)
        # Implementation
      end

      def send_to_openai_embedding_api(question, answer)
        # Implementation
      end
    end
  end
end
