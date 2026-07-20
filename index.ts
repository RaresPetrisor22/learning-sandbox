type Pizza = {
  id: number;
  name: string;
  price: number;
};

type Order = {
  id: number;
  pizza: Pizza;
  status: "ordered" | "completed";
};

let nextPizzaId: number = 0;

const menu: Pizza[] = [
  { id: nextPizzaId++, name: "Margherita", price: 8 },
  { id: nextPizzaId++, name: "Pepperoni", price: 10 },
  { id: nextPizzaId++, name: "Hawaiian", price: 9 },
  { id: nextPizzaId++, name: "Veggie", price: 9 },
];

let cashInRegister: number = 100;
const orderQueue: Order[] = [];
let nextOrderId: number = 1;

function addNewPizza(pizzaObj: Omit<Pizza, "id">): Pizza {
  const pizza: Pizza = { id: nextPizzaId++, ...pizzaObj };
  menu.push(pizza);
  return pizza;
}

function placeOrder(pizzaName: string): Order | undefined {
  const pizza = menu.find((pizza) => pizza.name === pizzaName);
  if (pizza) {
    cashInRegister += pizza.price;
    const order: Order = { id: nextOrderId++, pizza: pizza, status: "ordered" };
    orderQueue.push(order);
    return order;
  } else {
    console.error(`Pizza "${pizzaName}" is not available in the menu.`);
  }
}

function completeOrder(orderID: number): Order | undefined {
  const order = orderQueue.find((order) => order.id === orderID);
  if (order) {
    order.status = "completed";
    return order;
  } else {
    console.error(`Order with ID "${orderID}" is not found.`);
  }
}

export function getPizzaDetails(
  identifier: string | number,
): Pizza | undefined {
  if (typeof identifier === "string") {
    const pizza = menu.find(
      (pizza) => pizza.name.toLowerCase() === identifier.toLowerCase(),
    );
    return pizza;
  } else if (typeof identifier === "number") {
    const pizza = menu.find((pizza) => pizza.id === identifier);
    return pizza;
  } else {
    console.error(
      "Invalid identifier type. Please provide a string or number.",
    );
  }
}

addNewPizza({ name: "Buffalo", price: 11 });
addNewPizza({ name: "Meat Lovers", price: 13 });

placeOrder("Buffalo");
completeOrder(1);

console.log("Menu:", menu);
console.log("Order Queue:", orderQueue);
console.log("Cash in Register:", cashInRegister);
