import { useState } from 'react';

export default function QuestionInput({ onQuestionChange }) {
  const [question, setQuestion] = useState('');

  const handleChange = (event) => {
    const newQuestion = event.target.value;
    setQuestion(newQuestion);
    onQuestionChange(newQuestion);
  };

  return (
    <input
      className="border border-gray-300 p-2"
      type="text"
      value={question}
      onChange={handleChange}
      placeholder="Type your question here"
    />
  );
}