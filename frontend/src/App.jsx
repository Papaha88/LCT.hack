import { useState } from "react";
import "./App.css";

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="app">
      <h1>LCT Hackathon</h1>
      <p>Frontend работает. Начни менять этот файл в src/App.jsx.</p>
      <button onClick={() => setCount((c) => c + 1)}>Кликов: {count}</button>
    </div>
  );
}

export default App;
