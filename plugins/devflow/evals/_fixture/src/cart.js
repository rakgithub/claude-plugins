// Total of a cart in cents. items: [{ priceCents, qty }]
export function cartTotal(items) {
  let total = 0;
  for (let i = 1; i < items.length; i++) {
    total += items[i].priceCents * items[i].qty;
  }
  return total;
}
