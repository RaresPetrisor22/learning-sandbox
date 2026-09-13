# React Habit Tracker

**Source:** https://youtu.be/9aTRnV6g0eQ (Web Dev Simplified)

A simple habit tracker built as an introduction to React fundamentals.

## Tech Stack

- React 19 + TypeScript + Vite
- Tailwind CSS

## What I Learned

- Thinking in components and breaking the UI into custom, reusable pieces (`Button`, `HabitForm`, `HabitList`, `HabitItem`).
- Passing data between components with props, including more advanced patterns (children, callback props).
- Rendering arrays of data into lists of components.
- `useState` for local component state and conditional rendering based on it.
- `useContext` for sharing habit state across components without prop drilling.
- The Rules of Hooks, and extracting reusable logic into a custom hook (`useLocalStorage`).
- `useEffect` for syncing state with side effects (persisting habits to local storage).

## Folder Structure

- `src/components/` - `Header`, `HabitForm`, `HabitList`, `Button`
- `src/context/HabitProvider.tsx` - context provider holding the habit list state
- `src/hooks/useLocalStorage.ts` - custom hook for persisting state to local storage

## How to Run

1. Install dependencies: `npm install`
2. Start the dev server: `npm run dev`
