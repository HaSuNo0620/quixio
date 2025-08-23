import React, { createContext, useContext, useState } from 'react';

const ThemeContext = createContext();

const themes = {
  light: {
    background: "#F5F5F5",
    boardBackground: "#FFFFFF",
    textColor: "#333",
    xColor: "#E63946",
    oColor: "#457B9D",
    buttonBackground: "#4CAF50",
    buttonText: "white",
  },
  dark: {
    background: "#181818",
    boardBackground: "#282828",
    textColor: "#EEE",
    xColor: "#FF6F61",
    oColor: "#7AA8FF",
    buttonBackground: "#2E8B57",
    buttonText: "#FFF",
  },
};

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState('light');

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light');
  };


  return (
  <ThemeContext.Provider value={{ theme, themes, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};


export const useTheme = () => useContext(ThemeContext);
