#include <cuda.h>

typedef texture<float4, cudaTextureType1D, cudaReadModeElementType> FloatTex;

FloatTex texA(0, cudaFilterModePoint, cudaAddressModeBorder);
FloatTex texB(0, cudaFilterModePoint, cudaAddressModeBorder);

extern "C"
__global__ void __launch_bounds__(64) gemm64_2(
    int M, int N, int K,
    int LDA, int LDB,
    float* C, int LDC,
    float alpha, float beta) {
  // 2x512 float for strip A/B, double buffering
  __shared__ float4 shareA[256];
  __shared__ float4 shareB[256];
  // registers
  float rC[64] = {0};
  //float rC[64];
  float4 rA[2][2];
  float4 rB[2][2];
  float4 loadX0, loadX2, loadX4, loadX6;
  
  int tid = threadIdx.x;
  int bx = blockIdx.x;
  int by = blockIdx.y;
  
  int blk, ldx, ldx4, ldx8;
  FloatTex tex = (tid > 31) ? texB : texA;
  float4* share = (tid > 31) ? shareB : shareA;
  if (tid > 31) {
    blk = by;
    ldx4 = LDB;
  } else {
    blk = bx;
    ldx4 = LDA;
  }
  
  // store the zeros in the share buffer
  // share[128].x = share[128].y = share[128].z = share[128].w = 0.;
  
  int tid2 = (tid >> 4) & 1;
  int tid15 = tid & 15;
  //int tid31 = tid & 31;
  //int tid32 = tid & 32;
  ldx = ldx4 >> 2;
  ldx8 = ldx4 + ldx4;

  // track0 is location to read from texture (texA/texB) [tid2, 64*blk+4*tid15]
  // track0 = (64 * blk + 4 * tid15 + ldx4 * tid2) / 4 (divide 4 due to float4)
  int track0 = (blk << 4) + tid15 + (ldx * tid2);
  int track2 = track0 + ldx + ldx;
  int track4 = track0 + ldx4;
  int track6 = track2 + ldx4;
  
  // end is the boundary of track0
  int end = track0 + (K - 8) * ldx;

  // writeS is location to write into shared memory (shareA/shareB) [tid2, 4*tid15]
  // writeS = (4 * tid15 + 64 * tid2) / 4
  int writeS = tid15 + tid2 * 16;

  // readAs/readBs is location to read from shared memory (shareA/shareB) for multiply
  int readAs = (tid >> 1) & 7;
  int readBs = ((tid & 0x30) >> 3) | (tid & 1);

  // load texture (texA/texB) to registers loadX0 - loadX6
  loadX0 = tex1Dfetch(tex, track0);
  loadX2 = tex1Dfetch(tex, track2);
  loadX4 = tex1Dfetch(tex, track4);
  loadX6 = tex1Dfetch(tex, track6);

  
  // init rC to 0
// #pragma unroll
//   for (int i = 0; i < 16; ++i) {
//     rC[i*4 + 0] = share[128].x;
//     rC[i*4 + 1] = share[128].y;
//     rC[i*4 + 2] = share[128].z;
//     rC[i*4 + 3] = share[128].w;
//     }

  // store loadX0 - loadX6 to shared memory
  share[writeS + 0*16] = loadX0;
  share[writeS + 2*16] = loadX2;
  share[writeS + 4*16] = loadX4;
  share[writeS + 6*16] = loadX6;

  track0 += ldx8;
  track2 += ldx8;
  track4 += ldx8;
  track6 += ldx8;

  __syncthreads();

  writeS ^= 128;
  
  rA[0][0] = shareA[readAs + 0*16 + 0];
  rB[0][0] = shareB[readBs + 0*16 + 0];
  rA[0][1] = shareA[readAs + 0*16 + 8];
  rB[0][1] = shareB[readBs + 0*16 + 8];
  
  //while (track0 < end) {
  while (track0 <= end)
  //for (int block_k = 0; block_k <= K - 8; block_k += 8)
  {
    // inner loop
    // auto generated code
    // Iter k = 0
    rC[ 0] = fma(rA[0][0].x, rB[0][0].x, rC[0]);
    rA[1][0] = shareA[readAs + 1*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[0][0].y, rB[0][0].x, rC[1]);
    rC[ 2] = fma(rA[0][0].z, rB[0][0].x, rC[2]);
    rB[1][0] = shareB[readBs + 1*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[0][0].w, rB[0][0].x, rC[3]);
    rC[ 4] = fma(rA[0][1].x, rB[0][0].x, rC[4]);
    rA[1][1] = shareA[readAs + 1*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[0][1].y, rB[0][0].x, rC[5]);
    rC[ 6] = fma(rA[0][1].z, rB[0][0].x, rC[6]);
    rB[1][1] = shareB[readBs + 1*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[0][1].w, rB[0][0].x, rC[7]);
    rC[ 8] = fma(rA[0][0].x, rB[0][0].y, rC[8]);
    rC[ 9] = fma(rA[0][0].y, rB[0][0].y, rC[9]);
    rC[10] = fma(rA[0][0].z, rB[0][0].y, rC[10]);
    rC[11] = fma(rA[0][0].w, rB[0][0].y, rC[11]);
    rC[12] = fma(rA[0][1].x, rB[0][0].y, rC[12]);
    rC[13] = fma(rA[0][1].y, rB[0][0].y, rC[13]);
    rC[14] = fma(rA[0][1].z, rB[0][0].y, rC[14]);
    rC[15] = fma(rA[0][1].w, rB[0][0].y, rC[15]);
    rC[16] = fma(rA[0][0].x, rB[0][0].z, rC[16]);
    rC[17] = fma(rA[0][0].y, rB[0][0].z, rC[17]);
    rC[18] = fma(rA[0][0].z, rB[0][0].z, rC[18]);
    rC[19] = fma(rA[0][0].w, rB[0][0].z, rC[19]);
    rC[20] = fma(rA[0][1].x, rB[0][0].z, rC[20]);
    rC[21] = fma(rA[0][1].y, rB[0][0].z, rC[21]);
    rC[22] = fma(rA[0][1].z, rB[0][0].z, rC[22]);
    rC[23] = fma(rA[0][1].w, rB[0][0].z, rC[23]);
    rC[24] = fma(rA[0][0].x, rB[0][0].w, rC[24]);
    rC[25] = fma(rA[0][0].y, rB[0][0].w, rC[25]);
    rC[26] = fma(rA[0][0].z, rB[0][0].w, rC[26]);
    rC[27] = fma(rA[0][0].w, rB[0][0].w, rC[27]);
    rC[28] = fma(rA[0][1].x, rB[0][0].w, rC[28]);
    rC[29] = fma(rA[0][1].y, rB[0][0].w, rC[29]);
    rC[30] = fma(rA[0][1].z, rB[0][0].w, rC[30]);
    rC[31] = fma(rA[0][1].w, rB[0][0].w, rC[31]);
    loadX0 = tex1Dfetch(tex, track0); // load next strip to register
    rC[32] = fma(rA[0][0].x, rB[0][1].x, rC[32]);
    rC[33] = fma(rA[0][0].y, rB[0][1].x, rC[33]);
    loadX2 = tex1Dfetch(tex, track2); // load next strip to register
    rC[34] = fma(rA[0][0].z, rB[0][1].x, rC[34]);
    rC[35] = fma(rA[0][0].w, rB[0][1].x, rC[35]);
    rC[36] = fma(rA[0][1].x, rB[0][1].x, rC[36]);
    rC[37] = fma(rA[0][1].y, rB[0][1].x, rC[37]);
    rC[38] = fma(rA[0][1].z, rB[0][1].x, rC[38]);
    rC[39] = fma(rA[0][1].w, rB[0][1].x, rC[39]);
    rC[40] = fma(rA[0][0].x, rB[0][1].y, rC[40]);
    rC[41] = fma(rA[0][0].y, rB[0][1].y, rC[41]);
    rC[42] = fma(rA[0][0].z, rB[0][1].y, rC[42]);
    rC[43] = fma(rA[0][0].w, rB[0][1].y, rC[43]);
    rC[44] = fma(rA[0][1].x, rB[0][1].y, rC[44]);
    rC[45] = fma(rA[0][1].y, rB[0][1].y, rC[45]);
    rC[46] = fma(rA[0][1].z, rB[0][1].y, rC[46]);
    rC[47] = fma(rA[0][1].w, rB[0][1].y, rC[47]);
    rC[48] = fma(rA[0][0].x, rB[0][1].z, rC[48]);
    rC[49] = fma(rA[0][0].y, rB[0][1].z, rC[49]);
    rC[50] = fma(rA[0][0].z, rB[0][1].z, rC[50]);
    rC[51] = fma(rA[0][0].w, rB[0][1].z, rC[51]);
    rC[52] = fma(rA[0][1].x, rB[0][1].z, rC[52]);
    rC[53] = fma(rA[0][1].y, rB[0][1].z, rC[53]);
    rC[54] = fma(rA[0][1].z, rB[0][1].z, rC[54]);
    rC[55] = fma(rA[0][1].w, rB[0][1].z, rC[55]);
    rC[56] = fma(rA[0][0].x, rB[0][1].w, rC[56]);
    rC[57] = fma(rA[0][0].y, rB[0][1].w, rC[57]);
    rC[58] = fma(rA[0][0].z, rB[0][1].w, rC[58]);
    rC[59] = fma(rA[0][0].w, rB[0][1].w, rC[59]);
    rC[60] = fma(rA[0][1].x, rB[0][1].w, rC[60]);
    rC[61] = fma(rA[0][1].y, rB[0][1].w, rC[61]);
    rC[62] = fma(rA[0][1].z, rB[0][1].w, rC[62]);
    rC[63] = fma(rA[0][1].w, rB[0][1].w, rC[63]);
    // Iter k = 1
    rC[ 0] = fma(rA[1][0].x, rB[1][0].x, rC[0]);
    rA[0][0] = shareA[readAs + 2*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[1][0].y, rB[1][0].x, rC[1]);
    rC[ 2] = fma(rA[1][0].z, rB[1][0].x, rC[2]);
    rB[0][0] = shareB[readBs + 2*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[1][0].w, rB[1][0].x, rC[3]);
    rC[ 4] = fma(rA[1][1].x, rB[1][0].x, rC[4]);
    rA[0][1] = shareA[readAs + 2*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[1][1].y, rB[1][0].x, rC[5]);
    rC[ 6] = fma(rA[1][1].z, rB[1][0].x, rC[6]);
    rB[0][1] = shareB[readBs + 2*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[1][1].w, rB[1][0].x, rC[7]);
    rC[ 8] = fma(rA[1][0].x, rB[1][0].y, rC[8]);
    rC[ 9] = fma(rA[1][0].y, rB[1][0].y, rC[9]);
    rC[10] = fma(rA[1][0].z, rB[1][0].y, rC[10]);
    rC[11] = fma(rA[1][0].w, rB[1][0].y, rC[11]);
    rC[12] = fma(rA[1][1].x, rB[1][0].y, rC[12]);
    rC[13] = fma(rA[1][1].y, rB[1][0].y, rC[13]);
    rC[14] = fma(rA[1][1].z, rB[1][0].y, rC[14]);
    rC[15] = fma(rA[1][1].w, rB[1][0].y, rC[15]);
    rC[16] = fma(rA[1][0].x, rB[1][0].z, rC[16]);
    rC[17] = fma(rA[1][0].y, rB[1][0].z, rC[17]);
    rC[18] = fma(rA[1][0].z, rB[1][0].z, rC[18]);
    rC[19] = fma(rA[1][0].w, rB[1][0].z, rC[19]);
    rC[20] = fma(rA[1][1].x, rB[1][0].z, rC[20]);
    rC[21] = fma(rA[1][1].y, rB[1][0].z, rC[21]);
    rC[22] = fma(rA[1][1].z, rB[1][0].z, rC[22]);
    rC[23] = fma(rA[1][1].w, rB[1][0].z, rC[23]);
    rC[24] = fma(rA[1][0].x, rB[1][0].w, rC[24]);
    rC[25] = fma(rA[1][0].y, rB[1][0].w, rC[25]);
    rC[26] = fma(rA[1][0].z, rB[1][0].w, rC[26]);
    rC[27] = fma(rA[1][0].w, rB[1][0].w, rC[27]);
    rC[28] = fma(rA[1][1].x, rB[1][0].w, rC[28]);
    rC[29] = fma(rA[1][1].y, rB[1][0].w, rC[29]);
    rC[30] = fma(rA[1][1].z, rB[1][0].w, rC[30]);
    rC[31] = fma(rA[1][1].w, rB[1][0].w, rC[31]);
    loadX4 = tex1Dfetch(tex, track4); // load next strip to register
    rC[32] = fma(rA[1][0].x, rB[1][1].x, rC[32]);
    rC[33] = fma(rA[1][0].y, rB[1][1].x, rC[33]);
    loadX6 = tex1Dfetch(tex, track6); // load next strip to register
    rC[34] = fma(rA[1][0].z, rB[1][1].x, rC[34]);
    rC[35] = fma(rA[1][0].w, rB[1][1].x, rC[35]);
    rC[36] = fma(rA[1][1].x, rB[1][1].x, rC[36]);
    rC[37] = fma(rA[1][1].y, rB[1][1].x, rC[37]);
    rC[38] = fma(rA[1][1].z, rB[1][1].x, rC[38]);
    rC[39] = fma(rA[1][1].w, rB[1][1].x, rC[39]);
    rC[40] = fma(rA[1][0].x, rB[1][1].y, rC[40]);
    rC[41] = fma(rA[1][0].y, rB[1][1].y, rC[41]);
    rC[42] = fma(rA[1][0].z, rB[1][1].y, rC[42]);
    rC[43] = fma(rA[1][0].w, rB[1][1].y, rC[43]);
    rC[44] = fma(rA[1][1].x, rB[1][1].y, rC[44]);
    rC[45] = fma(rA[1][1].y, rB[1][1].y, rC[45]);
    rC[46] = fma(rA[1][1].z, rB[1][1].y, rC[46]);
    rC[47] = fma(rA[1][1].w, rB[1][1].y, rC[47]);
    rC[48] = fma(rA[1][0].x, rB[1][1].z, rC[48]);
    rC[49] = fma(rA[1][0].y, rB[1][1].z, rC[49]);
    rC[50] = fma(rA[1][0].z, rB[1][1].z, rC[50]);
    rC[51] = fma(rA[1][0].w, rB[1][1].z, rC[51]);
    rC[52] = fma(rA[1][1].x, rB[1][1].z, rC[52]);
    rC[53] = fma(rA[1][1].y, rB[1][1].z, rC[53]);
    rC[54] = fma(rA[1][1].z, rB[1][1].z, rC[54]);
    rC[55] = fma(rA[1][1].w, rB[1][1].z, rC[55]);
    rC[56] = fma(rA[1][0].x, rB[1][1].w, rC[56]);
    rC[57] = fma(rA[1][0].y, rB[1][1].w, rC[57]);
    rC[58] = fma(rA[1][0].z, rB[1][1].w, rC[58]);
    rC[59] = fma(rA[1][0].w, rB[1][1].w, rC[59]);
    rC[60] = fma(rA[1][1].x, rB[1][1].w, rC[60]);
    rC[61] = fma(rA[1][1].y, rB[1][1].w, rC[61]);
    rC[62] = fma(rA[1][1].z, rB[1][1].w, rC[62]);
    rC[63] = fma(rA[1][1].w, rB[1][1].w, rC[63]);
    // Iter k = 2
    rC[ 0] = fma(rA[0][0].x, rB[0][0].x, rC[0]);
    rA[1][0] = shareA[readAs + 3*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[0][0].y, rB[0][0].x, rC[1]);
    rC[ 2] = fma(rA[0][0].z, rB[0][0].x, rC[2]);
    rB[1][0] = shareB[readBs + 3*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[0][0].w, rB[0][0].x, rC[3]);
    rC[ 4] = fma(rA[0][1].x, rB[0][0].x, rC[4]);
    rA[1][1] = shareA[readAs + 3*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[0][1].y, rB[0][0].x, rC[5]);
    rC[ 6] = fma(rA[0][1].z, rB[0][0].x, rC[6]);
    rB[1][1] = shareB[readBs + 3*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[0][1].w, rB[0][0].x, rC[7]);
    rC[ 8] = fma(rA[0][0].x, rB[0][0].y, rC[8]);
    rC[ 9] = fma(rA[0][0].y, rB[0][0].y, rC[9]);
    rC[10] = fma(rA[0][0].z, rB[0][0].y, rC[10]);
    rC[11] = fma(rA[0][0].w, rB[0][0].y, rC[11]);
    rC[12] = fma(rA[0][1].x, rB[0][0].y, rC[12]);
    rC[13] = fma(rA[0][1].y, rB[0][0].y, rC[13]);
    rC[14] = fma(rA[0][1].z, rB[0][0].y, rC[14]);
    rC[15] = fma(rA[0][1].w, rB[0][0].y, rC[15]);
    rC[16] = fma(rA[0][0].x, rB[0][0].z, rC[16]);
    rC[17] = fma(rA[0][0].y, rB[0][0].z, rC[17]);
    rC[18] = fma(rA[0][0].z, rB[0][0].z, rC[18]);
    rC[19] = fma(rA[0][0].w, rB[0][0].z, rC[19]);
    rC[20] = fma(rA[0][1].x, rB[0][0].z, rC[20]);
    rC[21] = fma(rA[0][1].y, rB[0][0].z, rC[21]);
    rC[22] = fma(rA[0][1].z, rB[0][0].z, rC[22]);
    rC[23] = fma(rA[0][1].w, rB[0][0].z, rC[23]);
    rC[24] = fma(rA[0][0].x, rB[0][0].w, rC[24]);
    rC[25] = fma(rA[0][0].y, rB[0][0].w, rC[25]);
    rC[26] = fma(rA[0][0].z, rB[0][0].w, rC[26]);
    rC[27] = fma(rA[0][0].w, rB[0][0].w, rC[27]);
    rC[28] = fma(rA[0][1].x, rB[0][0].w, rC[28]);
    rC[29] = fma(rA[0][1].y, rB[0][0].w, rC[29]);
    rC[30] = fma(rA[0][1].z, rB[0][0].w, rC[30]);
    rC[31] = fma(rA[0][1].w, rB[0][0].w, rC[31]);
    rC[32] = fma(rA[0][0].x, rB[0][1].x, rC[32]);
    rC[33] = fma(rA[0][0].y, rB[0][1].x, rC[33]);
    rC[34] = fma(rA[0][0].z, rB[0][1].x, rC[34]);
    rC[35] = fma(rA[0][0].w, rB[0][1].x, rC[35]);
    rC[36] = fma(rA[0][1].x, rB[0][1].x, rC[36]);
    rC[37] = fma(rA[0][1].y, rB[0][1].x, rC[37]);
    rC[38] = fma(rA[0][1].z, rB[0][1].x, rC[38]);
    rC[39] = fma(rA[0][1].w, rB[0][1].x, rC[39]);
    rC[40] = fma(rA[0][0].x, rB[0][1].y, rC[40]);
    rC[41] = fma(rA[0][0].y, rB[0][1].y, rC[41]);
    rC[42] = fma(rA[0][0].z, rB[0][1].y, rC[42]);
    rC[43] = fma(rA[0][0].w, rB[0][1].y, rC[43]);
    rC[44] = fma(rA[0][1].x, rB[0][1].y, rC[44]);
    rC[45] = fma(rA[0][1].y, rB[0][1].y, rC[45]);
    rC[46] = fma(rA[0][1].z, rB[0][1].y, rC[46]);
    rC[47] = fma(rA[0][1].w, rB[0][1].y, rC[47]);
    rC[48] = fma(rA[0][0].x, rB[0][1].z, rC[48]);
    rC[49] = fma(rA[0][0].y, rB[0][1].z, rC[49]);
    rC[50] = fma(rA[0][0].z, rB[0][1].z, rC[50]);
    rC[51] = fma(rA[0][0].w, rB[0][1].z, rC[51]);
    rC[52] = fma(rA[0][1].x, rB[0][1].z, rC[52]);
    rC[53] = fma(rA[0][1].y, rB[0][1].z, rC[53]);
    rC[54] = fma(rA[0][1].z, rB[0][1].z, rC[54]);
    rC[55] = fma(rA[0][1].w, rB[0][1].z, rC[55]);
    rC[56] = fma(rA[0][0].x, rB[0][1].w, rC[56]);
    rC[57] = fma(rA[0][0].y, rB[0][1].w, rC[57]);
    rC[58] = fma(rA[0][0].z, rB[0][1].w, rC[58]);
    rC[59] = fma(rA[0][0].w, rB[0][1].w, rC[59]);
    rC[60] = fma(rA[0][1].x, rB[0][1].w, rC[60]);
    rC[61] = fma(rA[0][1].y, rB[0][1].w, rC[61]);
    rC[62] = fma(rA[0][1].z, rB[0][1].w, rC[62]);
    rC[63] = fma(rA[0][1].w, rB[0][1].w, rC[63]);
    // Iter k = 3
    rC[ 0] = fma(rA[1][0].x, rB[1][0].x, rC[0]);
    rA[0][0] = shareA[readAs + 4*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[1][0].y, rB[1][0].x, rC[1]);
    rC[ 2] = fma(rA[1][0].z, rB[1][0].x, rC[2]);
    rB[0][0] = shareB[readBs + 4*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[1][0].w, rB[1][0].x, rC[3]);
    rC[ 4] = fma(rA[1][1].x, rB[1][0].x, rC[4]);
    rA[0][1] = shareA[readAs + 4*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[1][1].y, rB[1][0].x, rC[5]);
    rC[ 6] = fma(rA[1][1].z, rB[1][0].x, rC[6]);
    rB[0][1] = shareB[readBs + 4*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[1][1].w, rB[1][0].x, rC[7]);
    rC[ 8] = fma(rA[1][0].x, rB[1][0].y, rC[8]);
    rC[ 9] = fma(rA[1][0].y, rB[1][0].y, rC[9]);
    rC[10] = fma(rA[1][0].z, rB[1][0].y, rC[10]);
    rC[11] = fma(rA[1][0].w, rB[1][0].y, rC[11]);
    rC[12] = fma(rA[1][1].x, rB[1][0].y, rC[12]);
    rC[13] = fma(rA[1][1].y, rB[1][0].y, rC[13]);
    rC[14] = fma(rA[1][1].z, rB[1][0].y, rC[14]);
    rC[15] = fma(rA[1][1].w, rB[1][0].y, rC[15]);
    rC[16] = fma(rA[1][0].x, rB[1][0].z, rC[16]);
    rC[17] = fma(rA[1][0].y, rB[1][0].z, rC[17]);
    rC[18] = fma(rA[1][0].z, rB[1][0].z, rC[18]);
    rC[19] = fma(rA[1][0].w, rB[1][0].z, rC[19]);
    rC[20] = fma(rA[1][1].x, rB[1][0].z, rC[20]);
    rC[21] = fma(rA[1][1].y, rB[1][0].z, rC[21]);
    rC[22] = fma(rA[1][1].z, rB[1][0].z, rC[22]);
    rC[23] = fma(rA[1][1].w, rB[1][0].z, rC[23]);
    rC[24] = fma(rA[1][0].x, rB[1][0].w, rC[24]);
    rC[25] = fma(rA[1][0].y, rB[1][0].w, rC[25]);
    rC[26] = fma(rA[1][0].z, rB[1][0].w, rC[26]);
    rC[27] = fma(rA[1][0].w, rB[1][0].w, rC[27]);
    rC[28] = fma(rA[1][1].x, rB[1][0].w, rC[28]);
    rC[29] = fma(rA[1][1].y, rB[1][0].w, rC[29]);
    rC[30] = fma(rA[1][1].z, rB[1][0].w, rC[30]);
    rC[31] = fma(rA[1][1].w, rB[1][0].w, rC[31]);
    rC[32] = fma(rA[1][0].x, rB[1][1].x, rC[32]);
    rC[33] = fma(rA[1][0].y, rB[1][1].x, rC[33]);
    rC[34] = fma(rA[1][0].z, rB[1][1].x, rC[34]);
    rC[35] = fma(rA[1][0].w, rB[1][1].x, rC[35]);
    rC[36] = fma(rA[1][1].x, rB[1][1].x, rC[36]);
    rC[37] = fma(rA[1][1].y, rB[1][1].x, rC[37]);
    rC[38] = fma(rA[1][1].z, rB[1][1].x, rC[38]);
    rC[39] = fma(rA[1][1].w, rB[1][1].x, rC[39]);
    rC[40] = fma(rA[1][0].x, rB[1][1].y, rC[40]);
    rC[41] = fma(rA[1][0].y, rB[1][1].y, rC[41]);
    rC[42] = fma(rA[1][0].z, rB[1][1].y, rC[42]);
    rC[43] = fma(rA[1][0].w, rB[1][1].y, rC[43]);
    rC[44] = fma(rA[1][1].x, rB[1][1].y, rC[44]);
    rC[45] = fma(rA[1][1].y, rB[1][1].y, rC[45]);
    rC[46] = fma(rA[1][1].z, rB[1][1].y, rC[46]);
    rC[47] = fma(rA[1][1].w, rB[1][1].y, rC[47]);
    rC[48] = fma(rA[1][0].x, rB[1][1].z, rC[48]);
    rC[49] = fma(rA[1][0].y, rB[1][1].z, rC[49]);
    rC[50] = fma(rA[1][0].z, rB[1][1].z, rC[50]);
    rC[51] = fma(rA[1][0].w, rB[1][1].z, rC[51]);
    rC[52] = fma(rA[1][1].x, rB[1][1].z, rC[52]);
    rC[53] = fma(rA[1][1].y, rB[1][1].z, rC[53]);
    rC[54] = fma(rA[1][1].z, rB[1][1].z, rC[54]);
    rC[55] = fma(rA[1][1].w, rB[1][1].z, rC[55]);
    rC[56] = fma(rA[1][0].x, rB[1][1].w, rC[56]);
    rC[57] = fma(rA[1][0].y, rB[1][1].w, rC[57]);
    rC[58] = fma(rA[1][0].z, rB[1][1].w, rC[58]);
    rC[59] = fma(rA[1][0].w, rB[1][1].w, rC[59]);
    rC[60] = fma(rA[1][1].x, rB[1][1].w, rC[60]);
    rC[61] = fma(rA[1][1].y, rB[1][1].w, rC[61]);
    rC[62] = fma(rA[1][1].z, rB[1][1].w, rC[62]);
    rC[63] = fma(rA[1][1].w, rB[1][1].w, rC[63]);
    // Iter k = 4
    rC[ 0] = fma(rA[0][0].x, rB[0][0].x, rC[0]);
    rA[1][0] = shareA[readAs + 5*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[0][0].y, rB[0][0].x, rC[1]);
    rC[ 2] = fma(rA[0][0].z, rB[0][0].x, rC[2]);
    rB[1][0] = shareB[readBs + 5*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[0][0].w, rB[0][0].x, rC[3]);
    rC[ 4] = fma(rA[0][1].x, rB[0][0].x, rC[4]);
    rA[1][1] = shareA[readAs + 5*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[0][1].y, rB[0][0].x, rC[5]);
    rC[ 6] = fma(rA[0][1].z, rB[0][0].x, rC[6]);
    rB[1][1] = shareB[readBs + 5*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[0][1].w, rB[0][0].x, rC[7]);
    rC[ 8] = fma(rA[0][0].x, rB[0][0].y, rC[8]);
    rC[ 9] = fma(rA[0][0].y, rB[0][0].y, rC[9]);
    rC[10] = fma(rA[0][0].z, rB[0][0].y, rC[10]);
    rC[11] = fma(rA[0][0].w, rB[0][0].y, rC[11]);
    rC[12] = fma(rA[0][1].x, rB[0][0].y, rC[12]);
    rC[13] = fma(rA[0][1].y, rB[0][0].y, rC[13]);
    rC[14] = fma(rA[0][1].z, rB[0][0].y, rC[14]);
    rC[15] = fma(rA[0][1].w, rB[0][0].y, rC[15]);
    rC[16] = fma(rA[0][0].x, rB[0][0].z, rC[16]);
    rC[17] = fma(rA[0][0].y, rB[0][0].z, rC[17]);
    rC[18] = fma(rA[0][0].z, rB[0][0].z, rC[18]);
    rC[19] = fma(rA[0][0].w, rB[0][0].z, rC[19]);
    rC[20] = fma(rA[0][1].x, rB[0][0].z, rC[20]);
    rC[21] = fma(rA[0][1].y, rB[0][0].z, rC[21]);
    rC[22] = fma(rA[0][1].z, rB[0][0].z, rC[22]);
    rC[23] = fma(rA[0][1].w, rB[0][0].z, rC[23]);
    rC[24] = fma(rA[0][0].x, rB[0][0].w, rC[24]);
    rC[25] = fma(rA[0][0].y, rB[0][0].w, rC[25]);
    rC[26] = fma(rA[0][0].z, rB[0][0].w, rC[26]);
    rC[27] = fma(rA[0][0].w, rB[0][0].w, rC[27]);
    rC[28] = fma(rA[0][1].x, rB[0][0].w, rC[28]);
    rC[29] = fma(rA[0][1].y, rB[0][0].w, rC[29]);
    rC[30] = fma(rA[0][1].z, rB[0][0].w, rC[30]);
    rC[31] = fma(rA[0][1].w, rB[0][0].w, rC[31]);
    rC[32] = fma(rA[0][0].x, rB[0][1].x, rC[32]);
    rC[33] = fma(rA[0][0].y, rB[0][1].x, rC[33]);
    rC[34] = fma(rA[0][0].z, rB[0][1].x, rC[34]);
    rC[35] = fma(rA[0][0].w, rB[0][1].x, rC[35]);
    rC[36] = fma(rA[0][1].x, rB[0][1].x, rC[36]);
    rC[37] = fma(rA[0][1].y, rB[0][1].x, rC[37]);
    rC[38] = fma(rA[0][1].z, rB[0][1].x, rC[38]);
    rC[39] = fma(rA[0][1].w, rB[0][1].x, rC[39]);
    rC[40] = fma(rA[0][0].x, rB[0][1].y, rC[40]);
    rC[41] = fma(rA[0][0].y, rB[0][1].y, rC[41]);
    rC[42] = fma(rA[0][0].z, rB[0][1].y, rC[42]);
    rC[43] = fma(rA[0][0].w, rB[0][1].y, rC[43]);
    rC[44] = fma(rA[0][1].x, rB[0][1].y, rC[44]);
    rC[45] = fma(rA[0][1].y, rB[0][1].y, rC[45]);
    rC[46] = fma(rA[0][1].z, rB[0][1].y, rC[46]);
    rC[47] = fma(rA[0][1].w, rB[0][1].y, rC[47]);
    rC[48] = fma(rA[0][0].x, rB[0][1].z, rC[48]);
    rC[49] = fma(rA[0][0].y, rB[0][1].z, rC[49]);
    rC[50] = fma(rA[0][0].z, rB[0][1].z, rC[50]);
    rC[51] = fma(rA[0][0].w, rB[0][1].z, rC[51]);
    rC[52] = fma(rA[0][1].x, rB[0][1].z, rC[52]);
    rC[53] = fma(rA[0][1].y, rB[0][1].z, rC[53]);
    rC[54] = fma(rA[0][1].z, rB[0][1].z, rC[54]);
    rC[55] = fma(rA[0][1].w, rB[0][1].z, rC[55]);
    rC[56] = fma(rA[0][0].x, rB[0][1].w, rC[56]);
    rC[57] = fma(rA[0][0].y, rB[0][1].w, rC[57]);
    rC[58] = fma(rA[0][0].z, rB[0][1].w, rC[58]);
    rC[59] = fma(rA[0][0].w, rB[0][1].w, rC[59]);
    rC[60] = fma(rA[0][1].x, rB[0][1].w, rC[60]);
    rC[61] = fma(rA[0][1].y, rB[0][1].w, rC[61]);
    rC[62] = fma(rA[0][1].z, rB[0][1].w, rC[62]);
    rC[63] = fma(rA[0][1].w, rB[0][1].w, rC[63]);
    // Iter k = 5
    rC[ 0] = fma(rA[1][0].x, rB[1][0].x, rC[0]);
    rA[0][0] = shareA[readAs + 6*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[1][0].y, rB[1][0].x, rC[1]);
    rC[ 2] = fma(rA[1][0].z, rB[1][0].x, rC[2]);
    rB[0][0] = shareB[readBs + 6*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[1][0].w, rB[1][0].x, rC[3]);
    rC[ 4] = fma(rA[1][1].x, rB[1][0].x, rC[4]);
    rA[0][1] = shareA[readAs + 6*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[1][1].y, rB[1][0].x, rC[5]);
    rC[ 6] = fma(rA[1][1].z, rB[1][0].x, rC[6]);
    rB[0][1] = shareB[readBs + 6*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[1][1].w, rB[1][0].x, rC[7]);
    rC[ 8] = fma(rA[1][0].x, rB[1][0].y, rC[8]);
    rC[ 9] = fma(rA[1][0].y, rB[1][0].y, rC[9]);
    rC[10] = fma(rA[1][0].z, rB[1][0].y, rC[10]);
    rC[11] = fma(rA[1][0].w, rB[1][0].y, rC[11]);
    rC[12] = fma(rA[1][1].x, rB[1][0].y, rC[12]);
    rC[13] = fma(rA[1][1].y, rB[1][0].y, rC[13]);
    rC[14] = fma(rA[1][1].z, rB[1][0].y, rC[14]);
    rC[15] = fma(rA[1][1].w, rB[1][0].y, rC[15]);
    rC[16] = fma(rA[1][0].x, rB[1][0].z, rC[16]);
    rC[17] = fma(rA[1][0].y, rB[1][0].z, rC[17]);
    rC[18] = fma(rA[1][0].z, rB[1][0].z, rC[18]);
    rC[19] = fma(rA[1][0].w, rB[1][0].z, rC[19]);
    rC[20] = fma(rA[1][1].x, rB[1][0].z, rC[20]);
    rC[21] = fma(rA[1][1].y, rB[1][0].z, rC[21]);
    rC[22] = fma(rA[1][1].z, rB[1][0].z, rC[22]);
    rC[23] = fma(rA[1][1].w, rB[1][0].z, rC[23]);
    rC[24] = fma(rA[1][0].x, rB[1][0].w, rC[24]);
    rC[25] = fma(rA[1][0].y, rB[1][0].w, rC[25]);
    rC[26] = fma(rA[1][0].z, rB[1][0].w, rC[26]);
    rC[27] = fma(rA[1][0].w, rB[1][0].w, rC[27]);
    rC[28] = fma(rA[1][1].x, rB[1][0].w, rC[28]);
    rC[29] = fma(rA[1][1].y, rB[1][0].w, rC[29]);
    rC[30] = fma(rA[1][1].z, rB[1][0].w, rC[30]);
    share[writeS + 0*16] = loadX0; // store register to shared memory
    rC[31] = fma(rA[1][1].w, rB[1][0].w, rC[31]);
    rC[32] = fma(rA[1][0].x, rB[1][1].x, rC[32]);
    rC[33] = fma(rA[1][0].y, rB[1][1].x, rC[33]);
    rC[34] = fma(rA[1][0].z, rB[1][1].x, rC[34]);
    share[writeS + 2*16] = loadX2; // store register to shared memory
    rC[35] = fma(rA[1][0].w, rB[1][1].x, rC[35]);
    rC[36] = fma(rA[1][1].x, rB[1][1].x, rC[36]);
    rC[37] = fma(rA[1][1].y, rB[1][1].x, rC[37]);
    rC[38] = fma(rA[1][1].z, rB[1][1].x, rC[38]);
    rC[39] = fma(rA[1][1].w, rB[1][1].x, rC[39]);
    rC[40] = fma(rA[1][0].x, rB[1][1].y, rC[40]);
    rC[41] = fma(rA[1][0].y, rB[1][1].y, rC[41]);
    rC[42] = fma(rA[1][0].z, rB[1][1].y, rC[42]);
    rC[43] = fma(rA[1][0].w, rB[1][1].y, rC[43]);
    rC[44] = fma(rA[1][1].x, rB[1][1].y, rC[44]);
    rC[45] = fma(rA[1][1].y, rB[1][1].y, rC[45]);
    rC[46] = fma(rA[1][1].z, rB[1][1].y, rC[46]);
    rC[47] = fma(rA[1][1].w, rB[1][1].y, rC[47]);
    rC[48] = fma(rA[1][0].x, rB[1][1].z, rC[48]);
    rC[49] = fma(rA[1][0].y, rB[1][1].z, rC[49]);
    rC[50] = fma(rA[1][0].z, rB[1][1].z, rC[50]);
    rC[51] = fma(rA[1][0].w, rB[1][1].z, rC[51]);
    rC[52] = fma(rA[1][1].x, rB[1][1].z, rC[52]);
    rC[53] = fma(rA[1][1].y, rB[1][1].z, rC[53]);
    rC[54] = fma(rA[1][1].z, rB[1][1].z, rC[54]);
    rC[55] = fma(rA[1][1].w, rB[1][1].z, rC[55]);
    rC[56] = fma(rA[1][0].x, rB[1][1].w, rC[56]);
    rC[57] = fma(rA[1][0].y, rB[1][1].w, rC[57]);
    rC[58] = fma(rA[1][0].z, rB[1][1].w, rC[58]);
    rC[59] = fma(rA[1][0].w, rB[1][1].w, rC[59]);
    rC[60] = fma(rA[1][1].x, rB[1][1].w, rC[60]);
    rC[61] = fma(rA[1][1].y, rB[1][1].w, rC[61]);
    rC[62] = fma(rA[1][1].z, rB[1][1].w, rC[62]);
    rC[63] = fma(rA[1][1].w, rB[1][1].w, rC[63]);
    // Iter k = 6
    rC[ 0] = fma(rA[0][0].x, rB[0][0].x, rC[0]);
    rA[1][0] = shareA[readAs + 7*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[0][0].y, rB[0][0].x, rC[1]);
    rC[ 2] = fma(rA[0][0].z, rB[0][0].x, rC[2]);
    rB[1][0] = shareB[readBs + 7*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[0][0].w, rB[0][0].x, rC[3]);
    rC[ 4] = fma(rA[0][1].x, rB[0][0].x, rC[4]);
    rA[1][1] = shareA[readAs + 7*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[0][1].y, rB[0][0].x, rC[5]);
    rC[ 6] = fma(rA[0][1].z, rB[0][0].x, rC[6]);
    rB[1][1] = shareB[readBs + 7*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[0][1].w, rB[0][0].x, rC[7]);
    rC[ 8] = fma(rA[0][0].x, rB[0][0].y, rC[8]);
    rC[ 9] = fma(rA[0][0].y, rB[0][0].y, rC[9]);
    rC[10] = fma(rA[0][0].z, rB[0][0].y, rC[10]);
    rC[11] = fma(rA[0][0].w, rB[0][0].y, rC[11]);
    rC[12] = fma(rA[0][1].x, rB[0][0].y, rC[12]);
    rC[13] = fma(rA[0][1].y, rB[0][0].y, rC[13]);
    rC[14] = fma(rA[0][1].z, rB[0][0].y, rC[14]);
    rC[15] = fma(rA[0][1].w, rB[0][0].y, rC[15]);
    rC[16] = fma(rA[0][0].x, rB[0][0].z, rC[16]);
    rC[17] = fma(rA[0][0].y, rB[0][0].z, rC[17]);
    rC[18] = fma(rA[0][0].z, rB[0][0].z, rC[18]);
    rC[19] = fma(rA[0][0].w, rB[0][0].z, rC[19]);
    rC[20] = fma(rA[0][1].x, rB[0][0].z, rC[20]);
    rC[21] = fma(rA[0][1].y, rB[0][0].z, rC[21]);
    rC[22] = fma(rA[0][1].z, rB[0][0].z, rC[22]);
    rC[23] = fma(rA[0][1].w, rB[0][0].z, rC[23]);
    rC[24] = fma(rA[0][0].x, rB[0][0].w, rC[24]);
    rC[25] = fma(rA[0][0].y, rB[0][0].w, rC[25]);
    rC[26] = fma(rA[0][0].z, rB[0][0].w, rC[26]);
    rC[27] = fma(rA[0][0].w, rB[0][0].w, rC[27]);
    rC[28] = fma(rA[0][1].x, rB[0][0].w, rC[28]);
    rC[29] = fma(rA[0][1].y, rB[0][0].w, rC[29]);
    rC[30] = fma(rA[0][1].z, rB[0][0].w, rC[30]);
    share[writeS + 4*16] = loadX4; // store register to shared memory
    rC[31] = fma(rA[0][1].w, rB[0][0].w, rC[31]);
    rC[32] = fma(rA[0][0].x, rB[0][1].x, rC[32]);
    rC[33] = fma(rA[0][0].y, rB[0][1].x, rC[33]);
    rC[34] = fma(rA[0][0].z, rB[0][1].x, rC[34]);
    share[writeS + 6*16] = loadX6; // store register to shared memory
    rC[35] = fma(rA[0][0].w, rB[0][1].x, rC[35]);
    rC[36] = fma(rA[0][1].x, rB[0][1].x, rC[36]);
    rC[37] = fma(rA[0][1].y, rB[0][1].x, rC[37]);
    rC[38] = fma(rA[0][1].z, rB[0][1].x, rC[38]);
    rC[39] = fma(rA[0][1].w, rB[0][1].x, rC[39]);
    rC[40] = fma(rA[0][0].x, rB[0][1].y, rC[40]);
    rC[41] = fma(rA[0][0].y, rB[0][1].y, rC[41]);
    rC[42] = fma(rA[0][0].z, rB[0][1].y, rC[42]);
    rC[43] = fma(rA[0][0].w, rB[0][1].y, rC[43]);
    rC[44] = fma(rA[0][1].x, rB[0][1].y, rC[44]);
    rC[45] = fma(rA[0][1].y, rB[0][1].y, rC[45]);
    rC[46] = fma(rA[0][1].z, rB[0][1].y, rC[46]);
    rC[47] = fma(rA[0][1].w, rB[0][1].y, rC[47]);
    rC[48] = fma(rA[0][0].x, rB[0][1].z, rC[48]);
    rC[49] = fma(rA[0][0].y, rB[0][1].z, rC[49]);
    rC[50] = fma(rA[0][0].z, rB[0][1].z, rC[50]);
    rC[51] = fma(rA[0][0].w, rB[0][1].z, rC[51]);
    rC[52] = fma(rA[0][1].x, rB[0][1].z, rC[52]);
    rC[53] = fma(rA[0][1].y, rB[0][1].z, rC[53]);
    rC[54] = fma(rA[0][1].z, rB[0][1].z, rC[54]);
    rC[55] = fma(rA[0][1].w, rB[0][1].z, rC[55]);
    rC[56] = fma(rA[0][0].x, rB[0][1].w, rC[56]);
    rC[57] = fma(rA[0][0].y, rB[0][1].w, rC[57]);
    rC[58] = fma(rA[0][0].z, rB[0][1].w, rC[58]);
    rC[59] = fma(rA[0][0].w, rB[0][1].w, rC[59]);
    rC[60] = fma(rA[0][1].x, rB[0][1].w, rC[60]);
    rC[61] = fma(rA[0][1].y, rB[0][1].w, rC[61]);
    rC[62] = fma(rA[0][1].z, rB[0][1].w, rC[62]);
    __syncthreads(); // sync till next strip is stored in shared memory
    readAs ^= 128; // togger readAs to read next A strip
    readBs ^= 128; // togger readBs to read next B strip
    writeS ^= 128; // togger writeS to write to the other shared memory buffer
    rC[63] = fma(rA[0][1].w, rB[0][1].w, rC[63]);
    // Iter k = 7
    rC[ 0] = fma(rA[1][0].x, rB[1][0].x, rC[0]);
    rA[0][0] = shareA[readAs + 0*16 + 0]; // load smem to regs
    rC[ 1] = fma(rA[1][0].y, rB[1][0].x, rC[1]);
    rC[ 2] = fma(rA[1][0].z, rB[1][0].x, rC[2]);
    rB[0][0] = shareB[readBs + 0*16 + 0]; // load smem to regs
    rC[ 3] = fma(rA[1][0].w, rB[1][0].x, rC[3]);
    rC[ 4] = fma(rA[1][1].x, rB[1][0].x, rC[4]);
    rA[0][1] = shareA[readAs + 0*16 + 8]; // load smem to regs
    rC[ 5] = fma(rA[1][1].y, rB[1][0].x, rC[5]);
    rC[ 6] = fma(rA[1][1].z, rB[1][0].x, rC[6]);
    rB[0][1] = shareB[readBs + 0*16 + 8]; // load smem to regs
    rC[ 7] = fma(rA[1][1].w, rB[1][0].x, rC[7]);
    rC[ 8] = fma(rA[1][0].x, rB[1][0].y, rC[8]);
    rC[ 9] = fma(rA[1][0].y, rB[1][0].y, rC[9]);
    rC[10] = fma(rA[1][0].z, rB[1][0].y, rC[10]);
    rC[11] = fma(rA[1][0].w, rB[1][0].y, rC[11]);
    rC[12] = fma(rA[1][1].x, rB[1][0].y, rC[12]);
    rC[13] = fma(rA[1][1].y, rB[1][0].y, rC[13]);
    rC[14] = fma(rA[1][1].z, rB[1][0].y, rC[14]);
    rC[15] = fma(rA[1][1].w, rB[1][0].y, rC[15]);
    rC[16] = fma(rA[1][0].x, rB[1][0].z, rC[16]);
    rC[17] = fma(rA[1][0].y, rB[1][0].z, rC[17]);
    rC[18] = fma(rA[1][0].z, rB[1][0].z, rC[18]);
    rC[19] = fma(rA[1][0].w, rB[1][0].z, rC[19]);
    rC[20] = fma(rA[1][1].x, rB[1][0].z, rC[20]);
    rC[21] = fma(rA[1][1].y, rB[1][0].z, rC[21]);
    rC[22] = fma(rA[1][1].z, rB[1][0].z, rC[22]);
    rC[23] = fma(rA[1][1].w, rB[1][0].z, rC[23]);
    rC[24] = fma(rA[1][0].x, rB[1][0].w, rC[24]);
    rC[25] = fma(rA[1][0].y, rB[1][0].w, rC[25]);
    rC[26] = fma(rA[1][0].z, rB[1][0].w, rC[26]);
    rC[27] = fma(rA[1][0].w, rB[1][0].w, rC[27]);
    rC[28] = fma(rA[1][1].x, rB[1][0].w, rC[28]);
    rC[29] = fma(rA[1][1].y, rB[1][0].w, rC[29]);
    rC[30] = fma(rA[1][1].z, rB[1][0].w, rC[30]);
    rC[31] = fma(rA[1][1].w, rB[1][0].w, rC[31]);
    rC[32] = fma(rA[1][0].x, rB[1][1].x, rC[32]);
    rC[33] = fma(rA[1][0].y, rB[1][1].x, rC[33]);
    rC[34] = fma(rA[1][0].z, rB[1][1].x, rC[34]);
    rC[35] = fma(rA[1][0].w, rB[1][1].x, rC[35]);
    rC[36] = fma(rA[1][1].x, rB[1][1].x, rC[36]);
    rC[37] = fma(rA[1][1].y, rB[1][1].x, rC[37]);
    rC[38] = fma(rA[1][1].z, rB[1][1].x, rC[38]);
    rC[39] = fma(rA[1][1].w, rB[1][1].x, rC[39]);
    rC[40] = fma(rA[1][0].x, rB[1][1].y, rC[40]);
    rC[41] = fma(rA[1][0].y, rB[1][1].y, rC[41]);
    rC[42] = fma(rA[1][0].z, rB[1][1].y, rC[42]);
    rC[43] = fma(rA[1][0].w, rB[1][1].y, rC[43]);
    rC[44] = fma(rA[1][1].x, rB[1][1].y, rC[44]);
    rC[45] = fma(rA[1][1].y, rB[1][1].y, rC[45]);
    rC[46] = fma(rA[1][1].z, rB[1][1].y, rC[46]);
    rC[47] = fma(rA[1][1].w, rB[1][1].y, rC[47]);
    rC[48] = fma(rA[1][0].x, rB[1][1].z, rC[48]);
    rC[49] = fma(rA[1][0].y, rB[1][1].z, rC[49]);
    rC[50] = fma(rA[1][0].z, rB[1][1].z, rC[50]);
    rC[51] = fma(rA[1][0].w, rB[1][1].z, rC[51]);
    rC[52] = fma(rA[1][1].x, rB[1][1].z, rC[52]);
    rC[53] = fma(rA[1][1].y, rB[1][1].z, rC[53]);
    rC[54] = fma(rA[1][1].z, rB[1][1].z, rC[54]);
    rC[55] = fma(rA[1][1].w, rB[1][1].z, rC[55]);
    rC[56] = fma(rA[1][0].x, rB[1][1].w, rC[56]);
    rC[57] = fma(rA[1][0].y, rB[1][1].w, rC[57]);
    rC[58] = fma(rA[1][0].z, rB[1][1].w, rC[58]);
    rC[59] = fma(rA[1][0].w, rB[1][1].w, rC[59]);
    rC[60] = fma(rA[1][1].x, rB[1][1].w, rC[60]);
    rC[61] = fma(rA[1][1].y, rB[1][1].w, rC[61]);
    rC[62] = fma(rA[1][1].z, rB[1][1].w, rC[62]);
    rC[63] = fma(rA[1][1].w, rB[1][1].w, rC[63]);
    track0 += ldx8;
    track2 += ldx8;
    track4 += ldx8;
    track6 += ldx8;
    
  }
  
  // write back to C
  int cx = (readAs & 0x7f) * 4;
  int cy = (readBs & 0x7f) * 4;
  C += (bx*64 + cx) + (by*64 + cy) * LDC;

  // auto generated code
  C[ 0 +  0*LDC] = rC[ 0] * alpha;
  C[ 1 +  0*LDC] = rC[ 1] * alpha;
  C[ 2 +  0*LDC] = rC[ 2] * alpha;
  C[ 3 +  0*LDC] = rC[ 3] * alpha;
  C[32 +  0*LDC] = rC[ 4] * alpha;
  C[33 +  0*LDC] = rC[ 5] * alpha;
  C[34 +  0*LDC] = rC[ 6] * alpha;
  C[35 +  0*LDC] = rC[ 7] * alpha;
  C[ 0 +  1*LDC] = rC[ 8] * alpha;
  C[ 1 +  1*LDC] = rC[ 9] * alpha;
  C[ 2 +  1*LDC] = rC[10] * alpha;
  C[ 3 +  1*LDC] = rC[11] * alpha;
  C[32 +  1*LDC] = rC[12] * alpha;
  C[33 +  1*LDC] = rC[13] * alpha;
  C[34 +  1*LDC] = rC[14] * alpha;
  C[35 +  1*LDC] = rC[15] * alpha;
  C[ 0 +  2*LDC] = rC[16] * alpha;
  C[ 1 +  2*LDC] = rC[17] * alpha;
  C[ 2 +  2*LDC] = rC[18] * alpha;
  C[ 3 +  2*LDC] = rC[19] * alpha;
  C[32 +  2*LDC] = rC[20] * alpha;
  C[33 +  2*LDC] = rC[21] * alpha;
  C[34 +  2*LDC] = rC[22] * alpha;
  C[35 +  2*LDC] = rC[23] * alpha;
  C[ 0 +  3*LDC] = rC[24] * alpha;
  C[ 1 +  3*LDC] = rC[25] * alpha;
  C[ 2 +  3*LDC] = rC[26] * alpha;
  C[ 3 +  3*LDC] = rC[27] * alpha;
  C[32 +  3*LDC] = rC[28] * alpha;
  C[33 +  3*LDC] = rC[29] * alpha;
  C[34 +  3*LDC] = rC[30] * alpha;
  C[35 +  3*LDC] = rC[31] * alpha;
  C[ 0 + 32*LDC] = rC[32] * alpha;
  C[ 1 + 32*LDC] = rC[33] * alpha;
  C[ 2 + 32*LDC] = rC[34] * alpha;
  C[ 3 + 32*LDC] = rC[35] * alpha;
  C[32 + 32*LDC] = rC[36] * alpha;
  C[33 + 32*LDC] = rC[37] * alpha;
  C[34 + 32*LDC] = rC[38] * alpha;
  C[35 + 32*LDC] = rC[39] * alpha;
  C[ 0 + 33*LDC] = rC[40] * alpha;
  C[ 1 + 33*LDC] = rC[41] * alpha;
  C[ 2 + 33*LDC] = rC[42] * alpha;
  C[ 3 + 33*LDC] = rC[43] * alpha;
  C[32 + 33*LDC] = rC[44] * alpha;
  C[33 + 33*LDC] = rC[45] * alpha;
  C[34 + 33*LDC] = rC[46] * alpha;
  C[35 + 33*LDC] = rC[47] * alpha;
  C[ 0 + 34*LDC] = rC[48] * alpha;
  C[ 1 + 34*LDC] = rC[49] * alpha;
  C[ 2 + 34*LDC] = rC[50] * alpha;
  C[ 3 + 34*LDC] = rC[51] * alpha;
  C[32 + 34*LDC] = rC[52] * alpha;
  C[33 + 34*LDC] = rC[53] * alpha;
  C[34 + 34*LDC] = rC[54] * alpha;
  C[35 + 34*LDC] = rC[55] * alpha;
  C[ 0 + 35*LDC] = rC[56] * alpha;
  C[ 1 + 35*LDC] = rC[57] * alpha;
  C[ 2 + 35*LDC] = rC[58] * alpha;
  C[ 3 + 35*LDC] = rC[59] * alpha;
  C[32 + 35*LDC] = rC[60] * alpha;
  C[33 + 35*LDC] = rC[61] * alpha;
  C[34 + 35*LDC] = rC[62] * alpha;
  C[35 + 35*LDC] = rC[63] * alpha;
}
