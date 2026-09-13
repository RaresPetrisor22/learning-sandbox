import { createContext, useContext, useState } from "react";
import { isSameDay } from "date-fns";

export type Habit = {
  id: string;
  name: string;
  completions: Date[];
};

type Context = {
  habits: Habit[];
  addHabit: (name: string) => void;
  deleteHabit: (name: string) => void;
  toggleHabit: (id: string, date: Date) => void;
};

type HabitProviderProps = {
  children: React.ReactNode;
};

export const HabitContext = createContext<null | Context>(null);

export function HabitProvider({ children }: HabitProviderProps) {
  const [habits, setHabits] = useState<Habit[]>([]);

  function addHabit(name: string) {
    setHabits((curr) => [
      ...curr,
      { id: crypto.randomUUID(), name, completions: [] },
    ]);
  }

  function deleteHabit(name: string) {
    setHabits((curr) => curr.filter((habit) => habit.name !== name));
  }

  function toggleHabit(id: string, date: Date) {
    setHabits((curr) =>
      curr.map((h) => {
        if (h.id !== id) return h;

        const isCompleted = h.completions.some((d) => isSameDay(d, date));
        const completions = isCompleted
          ? h.completions.filter((c) => !isSameDay(c, date))
          : [...h.completions, date];

        return { ...h, completions };
      }),
    );
  }

  return (
    <HabitContext value={{ habits, addHabit, deleteHabit, toggleHabit }}>
      {children}
    </HabitContext>
  );
}

export function useHabits() {
  const habitContext = useContext(HabitContext);

  if (!habitContext) {
    throw new Error("useHabits must be used within a HabitProvider");
  }
  return habitContext;
}
