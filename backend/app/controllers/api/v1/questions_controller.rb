module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        question = params[:question]

        # Check if question ends in ?

        # Check cache if question already exists

        # Read pages.csv file

        # Load embeddings embeddings.csv file

        # Answer question with context and get answer and context for saving

        # Cache answer, context, question

        # Return answer

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
