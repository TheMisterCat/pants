// dfpwm.js
export function decodeDFPWM(bytes) {
  // DFPWM state variables
  let charge = 0;
  let lastbit = 0;
  const output = new Float32Array(bytes.length * 8); // 8 samples per byte

  let sampleIndex = 0;
  for (let byte of bytes) {
    for (let i = 0; i < 8; i++) {
      let bit = (byte >> i) & 1;
      // AUKit decoding logic
      let delta = bit ? 1 : -1;
      charge += delta * (1 - 0.5); // strength from AUKit (~0.5)
      if (charge > 1) charge = 1;
      if (charge < -1) charge = -1;
      output[sampleIndex++] = charge;
      lastbit = bit;
    }
  }

  return output;
}
