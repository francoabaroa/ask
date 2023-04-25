require 'csv'
require 'ruby/openai'
require 'json'
require 'dotenv'
require 'resemble'
require 'nmatrix'
require 'numo/narray'

Dotenv.load('.env')

# use ada cause newer and cheaper, can replace DOC and QUERY and SEARCH
DOC_EMBEDDINGS_MODEL_ADA = "text-embedding-ada-002"
COMPLETIONS_MODEL = 'text-davinci-003'
MODEL_NAME = 'curie'

MAX_SECTION_LEN = 500
SEPARATOR = "\n* "
separator_len = 3

COMPLETIONS_API_PARAMS = {
  'temperature' => 0.0,
  'max_tokens' => 150,
  'model' => COMPLETIONS_MODEL
}

module Api
  module V1
    class QuestionsController < ApplicationController
      def ask
        question = params[:question]

        # Check if question ends in ?
        unless question.end_with?('?')
          question += '?'
        end

        # Check cache if question already exists

        # Read pages.csv file
        df = CSV.read('pdf-sample.pdf.pages.csv', headers: true)

        # Load embeddings embeddings.csv file
        document_embeddings = load_embeddings('pdf-sample.pdf.embeddings.csv')

        # Answer question with context and get answer and context for saving
        answer, context = answer_query_with_context(question, df, document_embeddings)

        # Cache answer, context, question

        # Return answer

        render json: { answer: answer }
      end

      private

      def load_embeddings(fname)
        """
        Read the document embeddings and their keys from a CSV.
        fname is the path to a CSV with exactly these named columns:
            "title", "0", "1", ... up to the length of the embedding vectors.
        """
        df = CSV.read(fname, headers: true)
        max_dim = df.headers.map(&:to_i).max
        df.each_with_object({}) do |row, h|
          h[row['title']] = (0..max_dim).map { |i| row[i.to_s].to_f }
        end
      end

      def get_embedding(text)
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        result = client.embeddings(
          engine: DOC_EMBEDDINGS_MODEL_ADA,
          prompt: text
        )
        result['choices'][0]['text'].strip
      end

      def vector_similarity(x, y)
        NMatrix[x] * NMatrix[y]
      end

      # Delete after figuring out which one to use
      def vector_similarity2(x, y)
        x_narray = Numo::DFloat[*x]
        y_narray = Numo::DFloat[*y]
        (x_narray * y_narray).sum
      end

      def answer_query_with_context(query, df, document_embeddings)
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        prompt, context = construct_prompt(query, document_embeddings, df)

        puts "===\n", prompt

        response = client.completions(
          prompt: prompt,
          temperature: COMPLETIONS_API_PARAMS['temperature'],
          max_tokens: COMPLETIONS_API_PARAMS['max_tokens'],
          model: COMPLETIONS_API_PARAMS['model']
        )

        return response['choices'][0]['text'].strip(" \n"), context
      end

      def construct_prompt(question, context_embeddings, df)
          """
          Fetch relevant embeddings
          """
          most_relevant_document_sections = order_document_sections_by_query_similarity(question, context_embeddings)

          chosen_sections = []
          chosen_sections_len = 0
          chosen_sections_indexes = []

          most_relevant_document_sections.each do |_, section_index|
              document_section = df.loc[df['title'] == section_index].iloc[0]

              chosen_sections_len += document_section.tokens + separator_len
              if chosen_sections_len > MAX_SECTION_LEN
                  space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
                  chosen_sections.append(SEPARATOR + document_section.content[0, space_left])
                  chosen_sections_indexes.append(section_index.to_s)
                  break
              end

              chosen_sections.append(SEPARATOR + document_section.content)
              chosen_sections_indexes.append(section_index.to_s)
          end

          header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""

          question_1 = "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
          question_2 = "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
          question_3 = "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
          question_4 = "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
          question_5 = "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
          question_6 = "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
          question_7 = "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
          question_8 = "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
          question_9 = "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
          question_10 = "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."

          return (header + chosen_sections.join + question_1 + question_2 + question_3 + question_4 + question_5 + question_6 + question_7 + question_8 + question_9 + question_10 + "\n\n\nQ: " + question + "\n\nA: "), (chosen_sections.join)
      end

      def order_document_sections_by_query_similarity(query, contexts)
          """
          Find the query embedding for the supplied query, and compare it against all of the pre-calculated document embeddings
          to find the most relevant sections.
          Return the list of document sections, sorted by relevance in descending order.
          """
          query_embedding = get_embedding(query)

          document_similarities = contexts.map { |doc_index, doc_embedding| [vector_similarity(query_embedding, doc_embedding), doc_index] }.sort.reverse

          return document_similarities
      end

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
