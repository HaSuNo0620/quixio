import React, { createContext, useContext, useState } from 'react';

const ThemeContext = createContext();

const themeDefinitions = {
  light: {
    background: '#F0F4F8',
    boardBackground: '#FFFFFF',
    cellBorder: '#C4CDD8',
    textColor: '#1A202C',
    subTextColor: '#4A5568',
    xColor: '#E8354A',
    oColor: '#2C7BE5',
    buttonBackground: '#2C7BE5',
    buttonText: '#FFFFFF',
    backButtonBackground: 'rgba(255,255,255,0.92)',
    backButtonColor: '#E8354A',
    selectedCell: 'rgba(246, 173, 85, 0.5)',
    outerCellBackground: 'rgba(44, 123, 229, 0.16)',
    outerCellBorder: 'rgba(44, 123, 229, 0.45)',
    boardShadowColor: '#A0AEC0',
    modalBackground: '#FFFFFF',
    modalOverlay: 'rgba(0,0,0,0.55)',
    modalButtonBackground: '#2C7BE5',
    modalButtonText: '#FFFFFF',
    modalSecondaryBackground: '#EDF2F7',
    modalSecondaryText: '#4A5568',
  },
  dark: {
    background: '#131A26',
    boardBackground: '#252D3D',
    cellBorder: '#3A4560',
    textColor: '#F7FAFC',
    subTextColor: '#A0AEC0',
    xColor: '#FF6B7A',
    oColor: '#5B9CF6',
    buttonBackground: '#2563EB',
    buttonText: '#FFFFFF',
    backButtonBackground: 'rgba(37,45,61,0.95)',
    backButtonColor: '#FF6B7A',
    selectedCell: 'rgba(246, 173, 85, 0.35)',
    outerCellBackground: 'rgba(91, 156, 246, 0.16)',
    outerCellBorder: 'rgba(91, 156, 246, 0.42)',
    boardShadowColor: '#0A0F1A',
    modalBackground: '#1E2A3D',
    modalOverlay: 'rgba(0,0,0,0.72)',
    modalButtonBackground: '#2563EB',
    modalButtonText: '#FFFFFF',
    modalSecondaryBackground: '#2D3A52',
    modalSecondaryText: '#CBD5E0',
  },
};

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState('light');
  const toggleTheme = () => setTheme((t) => (t === 'light' ? 'dark' : 'light'));
  return (
    <ThemeContext.Provider value={{ theme, themes: themeDefinitions[theme], toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
