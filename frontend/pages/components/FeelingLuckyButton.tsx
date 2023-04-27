interface FeelingLuckyButtonProps {
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  loading: boolean;
}

const FeelingLuckyButton: React.FC<FeelingLuckyButtonProps> = ({ onClick, loading }) => {
  return (
    <button
      className="w-full md:w-auto mx-2 bg-gray-200 hover:bg-gray-300 border-gray-200 text-gray-500 font-bold py-2 px-4 rounded"
      onClick={onClick}
      disabled={loading}
    >
      {"Feeling lucky"}
    </button>
  );
}

export default FeelingLuckyButton;