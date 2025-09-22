import React from 'react'
import { createRoot } from 'react-dom/client'
function App(){ return <div>Hello</div> }
const el=document.getElementById('root'); createRoot(el).render(<App />)
