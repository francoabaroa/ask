require 'dotenv'
require 'openai'
require 'pdf-reader'
require 'csv'
require 'tokenizers'

Dotenv.load('.env')

# Use ada cause newer and cheaper
DOC_EMBEDDINGS_MODEL_ADA = "text-embedding-ada-002"

# Simple whitespace-based tokenization - to be replaced with better method
def count_tokens(text)
  words = text.split
  words.size
end

def extract_pages(page_text, index)
  return [] if page_text.empty?
  content = page_text.split.join(' ')
  puts "page text: " + content
  outputs = [["Page #{index}", content, count_tokens(content) + 4]]
  outputs
end

def get_embedding(text, model)
  client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  result = client.embeddings(
      parameters: {
          model: model,
          input: text
      }
  )
  result["data"][0]["embedding"]
end

def get_doc_embedding(text)
  get_embedding(text, DOC_EMBEDDINGS_MODEL_ADA)
end

def compute_doc_embeddings(data)
  data.map.with_index { |row, index| [index, get_doc_embedding(row[1])] }.to_h
end

pdf_filename = ARGV[0] # Pass the PDF file as a command-line argument

reader = PDF::Reader.new(pdf_filename)

# Extract pages from PDF
res = []
i = 1
reader.pages.each do |page|
  res += extract_pages(page.text, i)
  i += 1
end

# Filter the data based on the 'tokens' value
res.select! { |row| row[2] < 2046 }

# Save the filtered data to a CSV file
CSV.open("#{pdf_filename}.pages.csv", 'w') do |csv|
  csv << ['title', 'content', 'tokens']
  res.each do |row|
    csv << row
  end
end

# Compute embeddings from OpenAI
doc_embeddings = compute_doc_embeddings(res)
CSV.open("#{pdf_filename}.embeddings.csv", "w") do |csv|
  csv << ["title"] + (0..doc_embeddings.values.first.length - 1).to_a
  doc_embeddings.each do |index, embedding|
    csv << ["Page #{index + 1}"] + embedding
  end
end