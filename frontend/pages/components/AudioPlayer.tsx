import React, { useEffect } from 'react';

interface Props {
  audioSrcUrl: string;
}

const AudioPlayer: React.FC<Props> = ({ audioSrcUrl }) => {
  useEffect(() => {
    const audio = document.getElementById('audio') as HTMLAudioElement;
    if (audio) {
      audio.autoplay = true;
    }
  }, [audioSrcUrl]);

  return (
    <audio id="audio" controls>
      <source src={audioSrcUrl} type="audio/wav" />
    </audio>
  );
};

export default AudioPlayer;
