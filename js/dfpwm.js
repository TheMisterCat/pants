// dfpwm.js
export function decodeDFPWM(bytes) {
  let charge = 0;        // AUKit: internal charge level
  let lastbit = 0;       // previous bit
  const output = new Float32Array(bytes.length * 8);

  // AUKit constants
  const strength = 0.25; // adjust to match AUKit smoothing
  const clamp = (v) => Math.max(-1, Math.min(1, v));

  let sampleIndex = 0;

  for (let byte of bytes) {
    for (let i = 0; i < 8; i++) {
      const bit = (byte >> i) & 1;
      const target = bit ? 1 : -1;

      // AUKit’s "charge += (target - charge) * strength" smoothing
      charge += (target - charge) * strength;

      // store in output
      output[sampleIndex++] = clamp(charge);

      lastbit = bit;
    }
  }

  return output;
}
