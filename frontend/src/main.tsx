import ReactDOM from 'react-dom/client';

import './index.css';
import "@/utils/matching";

import App from './app';

// Render the app
const rootElement = document.getElementById('root')!;
if (!rootElement.innerHTML) {
  const root = ReactDOM.createRoot(rootElement);
  root.render(<App />);
}
