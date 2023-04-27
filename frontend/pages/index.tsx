import { useState } from 'react';
import Image from 'next/image';
import { Inter } from 'next/font/google';

import AskQuestionButton from './components/AskQuestionButton';
import AnswerDisplay from './components/AnswerDisplay';
import FeelingLuckyButton from './components/FeelingLuckyButton';
import Footer from './components/Footer';
import QuestionInput from './components/QuestionInput';

const inter = Inter({ subsets: ['latin'] });
const API_URL = process.env.NEXT_PUBLIC_API_URL;

export default function Home() {
  const [answer, setAnswer] = useState('');
  const [error, setError] = useState('');
  const [feelingLuckyQuestion, setFeelingLuckyQuestion] = useState('');
  const [loading, setLoading] = useState(false);
  const [question, setQuestion] = useState('');

  const handleClearAnswer = () => {
    setAnswer('');
  };

  const handleClearFeelingLucky = () => {
    setFeelingLuckyQuestion('');
  };

  const handleFeelingLucky = () => {
    const options = ["What is a minimalist entrepreneur?", "What is your definition of community?", "How do I decide what kind of business I should start?"],
      random = ~~(Math.random() * options.length);
    const randomQuestion = options[random];
    setAnswer('');
    setQuestion(randomQuestion);
    setFeelingLuckyQuestion(randomQuestion);
    handleAskQuestionClick(randomQuestion);
  };

  const handleQuestionChange = (newQuestion: string) => {
    setQuestion(newQuestion);
  };

  const handleAskQuestionClick = async (luckyQuestion?: string) => {
    setError('');
    setLoading(true);
    const questionToAsk = luckyQuestion && luckyQuestion.length > 0 ? luckyQuestion : question;

    const response = await fetch(`${API_URL}/api/v1/questions/ask`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ question: questionToAsk }),
    });

    if (response.ok) {
      const data = await response.json();
      setAnswer(data.answer);
    } else {
      setError('An error occurred: ' + response.statusText);
      console.error('Error fetching answer:', response.statusText);
    }
    setLoading(false);
  };

  return (
    <main
      className={`flex min-h-screen flex-col items-center justify-between p-12 ${inter.className}`}
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
        <QuestionInput clearAnswer={handleClearAnswer} clearLuckyQuestion={handleClearFeelingLucky} feelingLuckyQuestion={feelingLuckyQuestion} onQuestionChange={handleQuestionChange} />
        <div className="flex flex-wrap justify-center">
          <AskQuestionButton loading={loading} onClick={handleAskQuestionClick} />
          <FeelingLuckyButton loading={loading} onClick={handleFeelingLucky} />
        </div>
        <AnswerDisplay answer={answer} />
        {error && <p>{error}</p>}
        <Footer />
      </div>
    </main>
  )
}
