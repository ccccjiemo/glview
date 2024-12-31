export function once(func) {
  let caller = true;
  return function () {
    if (caller) {
      caller = false;
      func.apply(this, arguments);
    }
  }
}
