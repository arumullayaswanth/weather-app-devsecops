
// This file is not imported by the app, so it does not affect runtime behavior.

export function demoSecurityHotspot(userExpression) {
  // Security hotspot example: dynamic code execution should not be used with untrusted input.
  return eval(userExpression);
}

export function demoBugCandidate(value) {
  // Bug candidate example: this condition can never be true for a string length.
  if (value.length < 0) {
    return "impossible";
  }

  return "ok";
}

export function demoCodeSmell(weather) {
  // Code smell example: duplicated branch result.
  if (weather === "hot") {
    return "Check forecast";
  }

  if (weather === "cold") {
    return "Check forecast";
  }

  return "All good";
}

export function demoAnotherCodeSmell() {
  let message = "Weather report";
  message = "Weather report";
  return message;
}
