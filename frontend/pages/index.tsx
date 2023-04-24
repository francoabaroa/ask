import { useState } from 'react';
import Image from 'next/image'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

function QuestionInput({ onQuestionChange }) {
  const [question, setQuestion] = useState('');

  const handleChange = (event: any) => {
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

function AskQuestionButton({ onClick }) {
  return (
    <button
      className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      onClick={onClick}
    >
      Ask question
    </button>
  );
}

function AnswerDisplay({ answer }) {
  return (
    <div className="border border-gray-300 p-4 mt-4">
      <h3 className="font-bold">Answer:</h3>
      <p>{answer}</p>
    </div>
  );
}
export default function Home() {
  return (
    <main
      className={`flex min-h-screen flex-col items-center justify-between p-24 ${inter.className}`}
    >
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm lg:flex">
        <p className="fixed left-0 top-0 flex w-full justify-center border-b border-gray-300 bg-gradient-to-b from-zinc-200 pb-6 pt-8 backdrop-blur-2xl dark:border-neutral-800 dark:bg-zinc-800/30 dark:from-inherit lg:static lg:w-auto  lg:rounded-xl lg:border lg:bg-gray-200 lg:p-4 lg:dark:bg-zinc-800/30">
          Ask
        </p>
      </div>
      <QuestionInput />
      <AskQuestionButton />
      <AnswerDisplay />
    </main>
  )
}
