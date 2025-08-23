import { registerRootComponent } from 'expo';
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator, CardStyleInterpolators } from '@react-navigation/stack';
import StartScreen from './screens/StartScreen';
import QuixioScreenPvP from './screens/QuixioScreenPvP';
import QuixioScreenAI from './screens/QuixioScreenAI';
import RulesScreen from './screens/RulesScreen';
import { ThemeProvider } from './components/ThemeConfig';

const Stack = createStackNavigator();

function App() {
  return (
    <ThemeProvider>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="StartScreen" screenOptions={{ headerShown: false }}>
          {/* タイトル画面 → ゲーム画面: 左から右 */}
          <Stack.Screen 
            name="StartScreen" 
            component={StartScreen} 
            options={{
              gestureDirection: "horizontal-inverted",
              cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS, 
            }} 
          />

          {/* ゲーム画面 → タイトル画面: 右から左 */}
          <Stack.Screen 
            name="QuixioScreenAI" 
            component={QuixioScreenAI} 
            options={{
              gestureDirection: "horizontal", 
              cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS, 
            }} 
          />
        
          {/* ゲーム画面 → タイトル画面: 右から左 */}
          <Stack.Screen 
            name="QuixioScreenPvP" 
            component={QuixioScreenPvP} 
            options={{
              gestureDirection: "horizontal", 
              cardStyleInterpolator: CardStyleInterpolators.forHorizontalIOS, 
            }} 
          />

          {/* ルール画面（デフォルトのアニメーション） */}
          <Stack.Screen 
            name="RulesScreen" 
            component={RulesScreen} 
          />
        </Stack.Navigator>
      </NavigationContainer>
    </ThemeProvider>
  );
}

// Expo のエントリーポイントとして登録
registerRootComponent(App);

export default App;
