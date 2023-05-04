# Ask My Book


## Things You'll Need
1. OpenAI API Key
2. Resemble API Key

## Setup

1. Fork and clone repository locally

### Backend Setup

2. `cd ./backend`
3. Create and fill in `.env` using `.env.example` as an example with the correct API keys
4. Install dependencies with command `bundle install`
5. Run db migrations with command `rails db:migrate`

### Frontend Setup

6. `cd ./frontend`
7. Create and fill in `.env.local` using `.env.sample` as an example
8. `NEXT_PUBLIC_API_URL=` should be set to your Rails backend url (most likely `http://localhost:4000` if you start locally using instructions below)
9. Install dependencies with command `npm install`

**Please note:**

- If you change frontend port (_default is port 3000_), make sure you update `backend/config/application.rb` CORS middleware to accept your new localhost url
- If you deploy the frontend to Vercel make sure to add it to the CORS middleware config as well
- If you deploy the backend, make sure you update `/frontend/package.json` "build" line under scripts object to include your backend deployment URL:
```
"scripts": {
    "dev": "next dev",
    "build": "NEXT_PUBLIC_API_URL=<YOUR_BACKEND_DEPLOYED_URL> next build",
    "start": "next start",
    "lint": "next lint"
  },
```

## Run Locally

1. In `/frontend` directory run `npm run dev` command to start frontend and will start in port 3000 unless you change it
2. In `/backend` directory run `rails server -p 4000`
3. Navigate to `http://localhost:3000` to access app

## Change Embedded PDF

If you want to change the embedded pdf, make sure it's titled `book.pdf`

Run the following command in the `/backend` directory

```
rails runner lib/tasks/format_pdf_manuscript.rb <PATH-TO-book.pdf>
```

Don't forget to update the book title name in `/frontend/pages/index.tsx` and relevant book info (_author name, bio, header, questions_) in `backend/app/controllers/api/v1/questions_controller.rb#L122`

## Potential Improvements
- Use OpenAI embeddings to find similar questions that have already been asked (_currently only checks for exact question in the DB_)
- Add upload PDF functionality on frontend so a user can land on the app, upload their PDF, and ask it any questions (_without having to update the code repo_)

## Testing

- No tests currently, but when I do implement I will test for the following:

### **Backend Testing**

- Use Rails' built-in testing framework for writing model, controller, and integration tests
- Test model validations, associations, and custom methods
- Test controller actions and API endpoints
- Test edge cases and error handling

### **Frontend Testing**

- Use a library like **`jest`** for writing tests for React components
- Test component rendering, user interactions, and API calls
- Test edge cases and error handling

## Architectural Decisions
- **Frontend**: NextJS, React, and Tailwind CSS were chosen for frontend development. NextJS provides an easy-to-use framework for building server-rendered React applications, which allows for better SEO and faster initial page loads. React facilitates the creation of reusable UI components and simplifies state management, making it easier to develop and maintain the app. Tailwind CSS is a utility-first CSS framework that enables rapid styling of components and ensures a consistent design throughout the app.
- **Backend**: Ruby on Rails was chosen for backend development due to its ease of use, rapid development capabilities, and extensive library support. Rails follows the MVC (Model-View-Controller) pattern, which promotes separation of concerns and makes it easier to manage and scale the application.
- **API**: A single API endpoint (POST /api/ask) was created to handle user questions. This endpoint receives the user's question, searches the book's embeddings for the answer, caches the answer, and sends a request to OpenAI's Embedding API. This design simplifies the communication between the frontend and backend, making it easier to maintain and scale the app.
- **CORS configuration**: To enable communication between the frontend and backend, CORS (Cross-Origin Resource Sharing) was configured in the backend. This allows the frontend to make requests to the backend API from different origins (e.g., localhost during development and the production domain).
- **Modular components**: The frontend components (QuestionInput, AskQuestionButton, and AnswerDisplay) were designed to be modular and reusable. This makes it easier to maintain and update the app, as changes to a specific component won't affect other parts of the application.

## Something Broken?
- Open an issue and I'll get back to you