import { useState } from 'react';
import Image from 'next/image';
import { Inter } from 'next/font/google';

import QuestionInput from './components/QuestionInput';
import AskQuestionButton from './components/AskQuestionButton';
import AnswerDisplay from './components/AnswerDisplay';

const inter = Inter({ subsets: ['latin'] });

export default function Home() {
  const [question, setQuestion] = useState('');
  const [answer, setAnswer] = useState('');

  const handleQuestionChange = (newQuestion: string) => {
    setQuestion(newQuestion);
  };

  const handleAskQuestionClick = async () => {
    const response = await fetch('http://localhost:4000/api/v1/questions/ask', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ question }),
    });

    if (response.ok) {
      const data = await response.json();
      setAnswer(data.answer);
    } else {
      console.error('Error fetching answer:', response.statusText);
    }
  };

  return (
    <main
      className={`flex min-h-screen flex-col items-center justify-between p-24 ${inter.className}`}
    >
      <div className="min-h-screen flex flex-col items-center p-4">
        <h1 className="text-4xl font-bold text-center mb-4">Ask My PDF</h1>
        <Image
          src="https://icons.iconarchive.com/icons/hopstarter/sleek-xp-basic/256/Document-icon.png"
          alt="example"
          width={150}
          height={150}
          className="w-32 h-32 mb-4"
        />
        <p className="text-l text-center mb-4">
          {"This is an experiment in using AI to make my book's content more accessible."}
        </p>
        <p className="text-l text-center mb-4">
          {"Ask a question and AI'll answer it in real-time:"}
        </p>
        <QuestionInput onQuestionChange={handleQuestionChange} />
        <AskQuestionButton onClick={handleAskQuestionClick} />
        <AnswerDisplay answer={answer} />
      </div>
    </main>
  )
}
