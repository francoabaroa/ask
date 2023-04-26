import { useState } from 'react';
import { Inter } from 'next/font/google'

import QuestionInput from './components/QuestionInput';
import AskQuestionButton from './components/AskQuestionButton';
import AnswerDisplay from './components/AnswerDisplay';

const inter = Inter({ subsets: ['latin'] })

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
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm lg:flex">
        <p className="fixed left-0 top-0 flex w-full justify-center border-b border-gray-300 bg-gradient-to-b from-zinc-200 pb-6 pt-8 backdrop-blur-2xl dark:border-neutral-800 dark:bg-zinc-800/30 dark:from-inherit lg:static lg:w-auto  lg:rounded-xl lg:border lg:bg-gray-200 lg:p-4 lg:dark:bg-zinc-800/30">
          Ask
        </p>
      </div>
      <QuestionInput onQuestionChange={handleQuestionChange} />
      <AskQuestionButton onClick={handleAskQuestionClick} />
      <AnswerDisplay answer={answer} />
    </main>
  )
}
