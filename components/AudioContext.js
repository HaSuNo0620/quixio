import React, { createContext, useContext, useState } from 'react';

const AudioContext = createContext({ isMuted: false, toggleMute: () => {} });

export const AudioProvider = ({ children }) => {
  const [isMuted, setIsMuted] = useState(false);
  const toggleMute = () => setIsMuted((m) => !m);
  return (
    <AudioContext.Provider value={{ isMuted, toggleMute }}>
      {children}
    </AudioContext.Provider>
  );
};

export const useAudio = () => useContext(AudioContext);
