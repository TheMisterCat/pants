export function decodeDFPWM(bytes) {
  let charge = 0;
  const strength = 0.25;
  const output = new Float32Array(bytes.length * 8);
  let sampleIndex = 0;
  const fadeSamples = 32;

  for (let byte of bytes) {
    for (let i = 0; i < 8; i++) {
      const bit = (byte >> i) & 1;
      const target = bit ? 1 : -1;
      charge += (target - charge) * strength;

      // fade-in first samples
      const fadeFactor = sampleIndex < fadeSamples ? sampleIndex / fadeSamples : 1;

      // normalize to ~0.3 peak
      output[sampleIndex++] = Math.max(-1, Math.min(1, charge)) * 0.3 * fadeFactor;
    }
  }
  return output;
}
