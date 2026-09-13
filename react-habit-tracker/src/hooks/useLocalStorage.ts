import { useState } from "react";

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = localStorage.getItem(key);

      if (item == null) return initialValue;

      return JSON.parse(item);
    } catch {
      return initialValue;
    }
  });
  return [storedValue, setStoredValue] as const;
}
