import { registerRootComponent } from 'expo';
import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator, CardStyleInterpolators } from '@react-navigation/stack';
import { useFonts, SpaceGrotesk_500Medium, SpaceGrotesk_600SemiBold, SpaceGrotesk_700Bold } from '@expo-google-fonts/space-grotesk';
import * as SplashScreen from 'expo-splash-screen';
import StartScreen from './screens/StartScreen';
import FiveonScreenPvP from './screens/FiveonScreenPvP';
import FiveonScreenAI from './screens/FiveonScreenAI';
import RulesScreen from './screens/RulesScreen';
import OnlineScreen from './screens/OnlineScreen';
import { ThemeProvider } from './components/ThemeConfig';
import { AudioProvider } from './components/AudioContext';
import { PurchaseProvider } from './components/PurchaseContext';

SplashScreen.preventAutoHideAsync();

const Stack = createStackNavigator();

function App() {
  useFonts({
    SpaceGrotesk_500Medium,
    SpaceGrotesk_600SemiBold,
    SpaceGrotesk_700Bold,
  });

  // フォント読み込みを待たず即座にスプラッシュを閉じてアプリを表示
  useEffect(() => {
    SplashScreen.hideAsync().catch(() => {});
  }, []);

  return (
    <AudioProvider>
      <ThemeProvider>
        <PurchaseProvider>
        <NavigationContainer>
          <Stack.Navigator initialRouteName="StartScreen" screenOptions={{ headerShown: false }}>
            <Stack.Screen
              name="StartScreen"
              component={StartScreen}
              options={{
                gestureDirection: 'horizontal-inverted',
                cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS,
              }}
            />
            <Stack.Screen
              name="FiveonScreenAI"
              component={FiveonScreenAI}
              options={{
                gestureDirection: 'horizontal',
                cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS,
              }}
            />
            <Stack.Screen
              name="FiveonScreenPvP"
              component={FiveonScreenPvP}
              options={{
                gestureDirection: 'horizontal',
                cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS,
              }}
            />
            <Stack.Screen name="RulesScreen" component={RulesScreen} />
            <Stack.Screen
              name="OnlineScreen"
              component={OnlineScreen}
              options={{
                gestureDirection: 'horizontal',
                cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS,
              }}
            />
          </Stack.Navigator>
        </NavigationContainer>
        </PurchaseProvider>
      </ThemeProvider>
    </AudioProvider>
  );
}

registerRootComponent(App);
export default App;
