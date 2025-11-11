// Browser-compatible DFPWM decoder (streaming)
export class DfpwmDecoder {
  constructor() {
    this.charge = 0;
    this.output = 0;
  }

  decode(bytes) {
    const out = new Float32Array(bytes.length);
    for (let i = 0; i < bytes.length; i++) {
      const bit = bytes[i] > 127 ? 1 : 0; // DFPWM bits
      this.charge += (bit ? 1 : -1) - this.charge >> 3;
      this.output += this.charge;
      // Clamp and convert to float32 in [-1,1]
      out[i] = Math.max(-128, Math.min(127, this.output)) / 128;
    }
    return out;
  }
}
